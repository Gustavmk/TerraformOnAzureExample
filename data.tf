data "template_file" "tf" {
  template = file("script.ps1")
}

data "azurerm_client_config" "current" {}
