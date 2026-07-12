# S01 (esperado) - Almacenamiento: Storage Account con versionado
# Equivalencia: aws_s3_bucket -> azurerm_storage_account (+ resource group)
#               aws_s3_bucket_versioning -> versioning en blob_properties
resource "azurerm_resource_group" "main" {
  name     = "rg-migraiac-s01"
  location = "eastus"
}

resource "azurerm_storage_account" "data" {
  name                     = "migraiacdatas01"
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  min_tls_version          = "TLS1_2"

  blob_properties {
    versioning_enabled = true
  }

  tags = {
    Environment = "dev"
    Project     = "migraiac"
  }
}
