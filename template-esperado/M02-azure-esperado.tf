# M02 (esperado) - Hosting estatico: Storage Account con seguridad y logging
# aws_s3_bucket(site)->storage_account ; versioning->blob_properties.versioning_enabled ;
# encryption->nativo ; public_access_block->allow_nested_items_to_be_public=false ;
# aws_s3_bucket(logs)->storage_account de logs
resource "azurerm_resource_group" "main" {
  name     = "rg-migraiac-m02"
  location = "eastus"
}

resource "azurerm_storage_account" "site" {
  name                            = "migraiacsitem02"
  resource_group_name             = azurerm_resource_group.main.name
  location                        = azurerm_resource_group.main.location
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false

  blob_properties {
    versioning_enabled = true
  }

  tags = { Name = "migraiac-site-m02" }
}

resource "azurerm_storage_account" "logs" {
  name                     = "migraiaclogsm02"
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  min_tls_version          = "TLS1_2"
}

resource "azurerm_storage_container" "site" {
  name                  = "web"
  storage_account_name  = azurerm_storage_account.site.name
  container_access_type = "private"
}
