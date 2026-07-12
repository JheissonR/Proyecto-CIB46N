resource "azurerm_resource_group" "main" {
  name     = "rg-migraiac-c02"
  location = "eastus"
}

resource "azurerm_cosmosdb_account" "main" {
  name                = "cosmos-migraiac-c02"
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

resource "azurerm_cosmosdb_table" "items" {
  name                = "migraiac-items-c02"
  resource_group_name = azurerm_resource_group.main.name
  account_name        = azurerm_cosmosdb_account.main.name
}

resource "azurerm_cosmosdb_table" "sessions" {
  name                = "migraiac-sessions-c02"
  resource_group_name = azurerm_resource_group.main.name
  account_name        = azurerm_cosmosdb_account.main.name
}

resource "azurerm_storage_account" "uploads" {
  name                     = "migraiacuploadsc02"
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  min_tls_version          = "TLS1_2"
  blob_properties {
    versioning_enabled = true
  }
}

resource "azurerm_service_plan" "fn" {
  name                = "plan-migraiac-c02"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  os_type             = "Linux"
  sku_name            = "Y1"
}

resource "azurerm_linux_function_app" "api" {
  name                       = "func-migraiac-c02"
  resource_group_name        = azurerm_resource_group.main.name
  location                   = azurerm_resource_group.main.location
  storage_account_name       = azurerm_storage_account.uploads.name
  storage_account_access_key = azurerm_storage_account.uploads.primary_access_key
  service_plan_id            = azurerm_service_plan.fn.id
  identity {
    type = "SystemAssigned"
  }
  site_config {
    application_stack {
      node_version = "18"
    }
  }
}

resource "azurerm_api_management" "main" {
  name                = "apim-migraiac-c02"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  publisher_name      = "MIGRAIAC"
  publisher_email     = "admin@migraiac.dev"
  sku_name            = "Consumption_0"
}

resource "azurerm_api_management_api" "items" {
  name                = "items-api-c02"
  resource_group_name = azurerm_resource_group.main.name
  api_management_name = azurerm_api_management.main.name
  revision            = "1"
  display_name        = "Items API"
  path                = "items"
  protocols           = ["https"]
}

resource "azurerm_api_management_api_operation" "get" {
  operation_id        = "get-items"
  api_name            = azurerm_api_management_api.items.name
  api_management_name = azurerm_api_management.main.name
  resource_group_name = azurerm_resource_group.main.name
  display_name        = "Get Items"
  method              = "GET"
  url_template        = "/"
}

resource "azurerm_api_management_api_operation" "post" {
  operation_id        = "post-items"
  api_name            = azurerm_api_management_api.items.name
  api_management_name = azurerm_api_management.main.name
  resource_group_name = azurerm_resource_group.main.name
  display_name        = "Post Items"
  method              = "POST"
  url_template        = "/"
}
