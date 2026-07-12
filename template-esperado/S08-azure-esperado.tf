# S08 (esperado) - Almacenamiento: Storage Account con cifrado
# Equivalencia: aws_s3_bucket -> azurerm_storage_account
#               aws_s3_bucket_server_side_encryption_configuration -> cifrado nativo (AES256 por defecto)
resource "azurerm_resource_group" "main" {
  name     = "rg-migraiac-s08"
  location = "eastus"
}

resource "azurerm_storage_account" "logs" {
  name                     = "migraiaclogss08"
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  min_tls_version          = "TLS1_2"

  infrastructure_encryption_enabled = true
}
