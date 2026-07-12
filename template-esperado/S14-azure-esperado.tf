# S14 (esperado) - Almacenamiento: Storage Account con politica de ciclo de vida
# Equivalencia: aws_s3_bucket -> azurerm_storage_account
#               aws_s3_bucket_lifecycle_configuration -> azurerm_storage_management_policy
resource "azurerm_resource_group" "main" {
  name     = "rg-migraiac-s14"
  location = "eastus"
}

resource "azurerm_storage_account" "archive" {
  name                     = "migraiacarchives14"
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  min_tls_version          = "TLS1_2"
}

resource "azurerm_storage_management_policy" "archive" {
  storage_account_id = azurerm_storage_account.archive.id

  rule {
    name    = "expire-old"
    enabled = true
    filters {
      blob_types = ["blockBlob"]
    }
    actions {
      base_blob {
        delete_after_days_since_modification_greater_than = 90
      }
    }
  }
}
