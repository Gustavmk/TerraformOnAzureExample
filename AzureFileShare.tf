
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
  quota                = 5
}

/*
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