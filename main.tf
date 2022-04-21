# ref: https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password
resource "random_password" "vm-admin-password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

variable "count_web" {
  type    = string
  default = "4"
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
  purge_protection_enabled   = "false"

  network_acls {
    bypass         = "AzureServices"
    default_action = "Allow"
  }

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
    azurerm_key_vault_access_policy.kv-lab-automation
  ]
}

resource "azurerm_public_ip" "lab-pip" {
  count               = var.count_web
  name                = "pip-lab-${count.index}"
  resource_group_name = azurerm_resource_group.rg-lab.name
  location            = azurerm_resource_group.rg-lab.location
  allocation_method   = "Static"
}

resource "azurerm_network_interface" "lab" {
  count               = var.count_web
  name                = "lab-nic-${count.index}"
  location            = azurerm_resource_group.rg-lab.location
  resource_group_name = azurerm_resource_group.rg-lab.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.lab.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = element(azurerm_public_ip.lab-pip.*.id, count.index)
  }
}

resource "azurerm_windows_virtual_machine" "lab" {
  count = var.count_web

  name                = "labweb${count.index}"
  resource_group_name = azurerm_resource_group.rg-lab.name
  location            = azurerm_resource_group.rg-lab.location
  size                = "Standard_B2s"
  admin_username      = "adminuser"
  admin_password      = azurerm_key_vault_secret.kv-secret-admin-vm.value
  timezone            = "E. South America Standard Time"

  network_interface_ids = [
    element(azurerm_network_interface.lab.*.id, count.index)
  ]

  winrm_listener {
    protocol = "Http"
  }

  os_disk {
    name                 = "OS_Disk_Lab${count.index}"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = 128
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
  count = var.count_web

  name                       = "WinRM-Ansible"
  virtual_machine_id         = element(azurerm_windows_virtual_machine.lab.*.id, count.index)
  publisher                  = "Microsoft.Compute"
  type                       = "CustomScriptExtension"
  type_handler_version       = "1.10"
  auto_upgrade_minor_version = true

  protected_settings = <<SETTINGS
  {
     "commandToExecute": "powershell -encodedCommand ${textencodebase64("${data.template_file.tf.rendered}", "UTF-16LE")}"
  }
  SETTINGS

  depends_on = [
    azurerm_windows_virtual_machine.lab
  ]
}


/*
resource "azurerm_storage_account" "storage_account" {
  name                = "${var.stg-name}${lower(random_id.kv-name.hex)}"
  resource_group_name = azurerm_resource_group.rg-lab.name
  location            = azurerm_resource_group.rg-lab.location

  account_kind             = "StorageV2"
  account_tier             = "Standard"
  account_replication_type = "LRS"
  access_tier              = "Cool"

  enable_https_traffic_only = true
}

resource "azurerm_storage_share" "files" {
  name                 = "files"
  storage_account_name = azurerm_storage_account.storage_account.name
  quota                = 10
}


locals {
  connect_file_share_script = templatefile("connect-azure-file-share.tpl.ps1", {
    storage_account_file_host = azurerm_storage_account.storage_account.primary_file_host
    storage_account_name      = azurerm_storage_account.storage_account.name
    storage_account_key       = azurerm_storage_account.storage_account.primary_access_key
    file_share_name           = azurerm_storage_share.files.name
    drive_letter              = "Z"
  })
}

resource "azurerm_virtual_machine_extension" "attach_file_share" {
  name                       = "attach_file_share"
  virtual_machine_id         = azurerm_windows_virtual_machine.lab.id
  publisher                  = "Microsoft.Compute"
  type                       = "CustomScriptExtension"
  type_handler_version       = "1.10"
  auto_upgrade_minor_version = true

  settings = jsonencode({
    commandToExecute = "powershell -EncodedCommand ${textencodebase64(local.connect_file_share_script, "UTF-16LE")}"
  })

  depends_on = [azurerm_storage_share.files]
}

*/