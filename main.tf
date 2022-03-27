resource "random_password" "vm-admin-password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "random_id" "kv-name" {
  byte_length = 4
}

resource "azurerm_resource_group" "rg-lab" {
  name     = var.rg-name
  location = "East US"
}

resource "azurerm_virtual_network" "lab" {
  name                = "lab-network"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg-lab.location
  resource_group_name = azurerm_resource_group.rg-lab.name
}

resource "azurerm_subnet" "lab" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.rg-lab.name
  virtual_network_name = azurerm_virtual_network.lab.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_key_vault" "kv-lab" {
  name                       = "${var.kv-name}-${lower(random_id.kv-name.hex)}"
  location                   = azurerm_resource_group.rg-lab.location
  resource_group_name        = azurerm_resource_group.rg-lab.name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  soft_delete_retention_days = 7
  enabled_for_deployment     = "true"
  enable_rbac_authorization  = "false"
  purge_protection_enabled = "false"

  network_acls {
    bypass = "AzureServices"
    default_action = "Allow"
  }

  depends_on = [
    azurerm_subnet.lab
  ]
}

resource "azurerm_key_vault_access_policy" "kv-lab-automation" {
  key_vault_id = azurerm_key_vault.kv-lab.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = data.azurerm_client_config.current.object_id

  key_permissions = [
    "Get",
    "Import",
    "List",
  ]

  secret_permissions = [
    "List",
    "Get",
    "Set",
  ]
}

resource "azurerm_key_vault_secret" "kv-secret-admin-vm" {
  name         = "vm-admin-password"
  value        = random_password.vm-admin-password.result
  key_vault_id = azurerm_key_vault.kv-lab.id

  depends_on = [
    azurerm_key_vault.kv-lab
  ]
}

resource "azurerm_public_ip" "lab-pip" {
  name                = "lab-pip"
  resource_group_name = azurerm_resource_group.rg-lab.name
  location            = azurerm_resource_group.rg-lab.location
  allocation_method   = "Static"
}

resource "azurerm_network_interface" "lab" {
  name                = "lab-nic"
  location            = azurerm_resource_group.rg-lab.location
  resource_group_name = azurerm_resource_group.rg-lab.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.lab.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.lab-pip.id
  }
}

resource "azurerm_windows_virtual_machine" "lab" {
  name                = "lab-machine"
  resource_group_name = azurerm_resource_group.rg-lab.name
  location            = azurerm_resource_group.rg-lab.location
  size                = "Standard_F2"
  admin_username      = "adminuser"
  admin_password      = azurerm_key_vault_secret.kv-secret-admin-vm.value
  network_interface_ids = [
    azurerm_network_interface.lab.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }
  
  tags = {
    role = "web"
  }

  depends_on = [
    azurerm_network_interface.lab
  ]
}

resource "azurerm_virtual_machine_extension" "vm-winrm" {
  name                 = "WinRM-Ansible"
  virtual_machine_id   = azurerm_windows_virtual_machine.lab.id
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.9"

  protected_settings = <<EOF
    {
        "commandToExecute": "powershell -command \"[System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('${base64encode(data.template_file.tf.rendered)}')) | Out-File -filepath script.ps1\" && powershell -ExecutionPolicy Unrestricted -File script.ps1"
    }
    EOF
  depends_on = [
    azurerm_windows_virtual_machine.lab
  ]
}

