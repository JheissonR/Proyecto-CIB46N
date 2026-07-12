# M10 (esperado) - CDN: Storage Account con Azure CDN
# aws_s3_bucket->storage_account(static_website) ; versioning->blob_properties ;
# encryption->nativo ; public_access_block->allow_nested_items_to_be_public=false ;
# aws_cloudfront_distribution->cdn_endpoint ; aws_cloudfront_origin_access_identity->(cdn origin)
resource "azurerm_resource_group" "main" {
  name     = "rg-migraiac-m10"
  location = "eastus"
}

resource "azurerm_storage_account" "site" {
  name                            = "migraiaccdnm10"
  resource_group_name             = azurerm_resource_group.main.name
  location                        = azurerm_resource_group.main.location
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false

  blob_properties {
    versioning_enabled = true
  }

  static_website {
    index_document = "index.html"
  }
}

resource "azurerm_cdn_profile" "main" {
  name                = "cdn-migraiac-m10"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "Standard_Microsoft"
}

resource "azurerm_cdn_endpoint" "main" {
  name                = "cdn-endpoint-migraiac-m10"
  profile_name        = azurerm_cdn_profile.main.name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  origin {
    name      = "storage-origin"
    host_name = azurerm_storage_account.site.primary_web_host
  }
}
