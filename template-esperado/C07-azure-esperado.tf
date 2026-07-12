# C07 (esperado) - Almacenamiento empresarial: Key Vault + Storage con replicacion
resource "azurerm_resource_group" "main" {
  name     = "rg-migraiac-c07"
  location = "eastus"
}

data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "main" {
  name                = "kv-migraiac-c07"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"
  purge_protection_enabled = true
}

resource "azurerm_key_vault_key" "main" {
  name         = "migraiac-key-c07"
  key_vault_id = azurerm_key_vault.main.id
  key_type     = "RSA"
  key_size     = 2048
  key_opts     = ["encrypt", "decrypt", "wrapKey", "unwrapKey"]
}

resource "azurerm_storage_account" "primary" {
  name                     = "migraiacprimaryc07"
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "GRS"
  min_tls_version          = "TLS1_2"
  blob_properties {
    versioning_enabled = true
  }
}

resource "azurerm_storage_account" "replica" {
  name                     = "migraiacreplicac07"
  resource_group_name      = azurerm_resource_group.main.name
  location                 = "westus"
  account_tier             = "Standard"
  account_replication_type = "LRS"
  min_tls_version          = "TLS1_2"
  blob_properties {
    versioning_enabled = true
  }
}

resource "azurerm_storage_account" "archive" {
  name                     = "migraiacarchivec07"
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  access_tier              = "Cool"
}

resource "azurerm_storage_account" "logs" {
  name                     = "migraiaclogsc07"
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_management_policy" "primary" {
  storage_account_id = azurerm_storage_account.primary.id
  rule {
    name    = "archive-old"
    enabled = true
    filters {
      blob_types = ["blockBlob"]
    }
    actions {
      base_blob {
        tier_to_archive_after_days_since_modification_greater_than = 90
      }
    }
  }
}

resource "azurerm_storage_management_policy" "archive" {
  storage_account_id = azurerm_storage_account.archive.id
  rule {
    name    = "expire"
    enabled = true
    filters {
      blob_types = ["blockBlob"]
    }
    actions {
      base_blob {
        delete_after_days_since_modification_greater_than = 365
      }
    }
  }
}

resource "azurerm_storage_object_replication" "primary_to_replica" {
  source_storage_account_id      = azurerm_storage_account.primary.id
  destination_storage_account_id = azurerm_storage_account.replica.id
  rules {
    source_container_name      = "data"
    destination_container_name = "data"
  }
}

resource "azurerm_cosmosdb_account" "metadata" {
  name                = "cosmos-migraiac-c07"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  offer_type          = "Standard"
  kind                = "GlobalDocumentDB"
  capabilities {
    name = "EnableTable"
  }
  consistency_policy {
    consistency_level = "Session"
  }
  geo_location {
    location          = azurerm_resource_group.main.location
    failover_priority = 0
  }
}

resource "azurerm_eventgrid_topic" "events" {
  name                = "egt-migraiac-c07"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}
