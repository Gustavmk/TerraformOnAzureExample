output "all-publicip" {
  value = azurerm_public_ip.lab-pip.ip_address
}