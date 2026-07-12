# C12 (esperado) - Telemetria a escala: Event Hub + Stream Analytics + Cosmos + Function App
resource "azurerm_resource_group" "main" {
  name     = "rg-migraiac-c12"
  location = "eastus"
}

resource "azurerm_eventhub_namespace" "main" {
  name                = "ehns-migraiac-c12"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "Standard"
  capacity            = 4
}

resource "azurerm_eventhub" "telemetry" {
  name                = "migraiac-telemetry-c12"
  namespace_name      = azurerm_eventhub_namespace.main.name
  resource_group_name = azurerm_resource_group.main.name
  partition_count     = 4
  message_retention   = 1
}

resource "azurerm_storage_account" "raw" {
  name                     = "migraiacrawc12"
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_cosmosdb_account" "main" {
  name                = "cosmos-migraiac-c12"
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

resource "azurerm_cosmosdb_table" "devices" {
  name                = "migraiac-devices-c12"
  resource_group_name = azurerm_resource_group.main.name
  account_name        = azurerm_cosmosdb_account.main.name
}

resource "azurerm_cosmosdb_table" "state" {
  name                = "migraiac-state-c12"
  resource_group_name = azurerm_resource_group.main.name
  account_name        = azurerm_cosmosdb_account.main.name
}

resource "azurerm_stream_analytics_job" "aggregate" {
  name                = "asa-migraiac-c12"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  streaming_units     = 3
  transformation_query = "SELECT * INTO output FROM input"
}

resource "azurerm_storage_account" "fn" {
  name                     = "migraiacfnc12"
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_service_plan" "fn" {
  name                = "plan-migraiac-c12"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  os_type             = "Linux"
  sku_name            = "Y1"
}

resource "azurerm_linux_function_app" "ingest" {
  name                       = "func-migraiac-c12"
  resource_group_name        = azurerm_resource_group.main.name
  location                   = azurerm_resource_group.main.location
  storage_account_name       = azurerm_storage_account.fn.name
  storage_account_access_key = azurerm_storage_account.fn.primary_access_key
  service_plan_id            = azurerm_service_plan.fn.id
  identity {
    type = "SystemAssigned"
  }
  site_config {
    application_stack {
      python_version = "3.11"
    }
  }
}

resource "azurerm_servicebus_namespace" "main" {
  name                = "sb-migraiac-c12"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "Standard"
}

resource "azurerm_servicebus_queue" "processing" {
  name         = "migraiac-processing-c12"
  namespace_id = azurerm_servicebus_namespace.main.id
}

resource "azurerm_log_analytics_workspace" "main" {
  name                = "log-migraiac-c12"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "PerGB2018"
  retention_in_days   = 7
}

resource "azurerm_monitor_action_group" "alerts" {
  name                = "ag-migraiac-c12"
  resource_group_name = azurerm_resource_group.main.name
  short_name          = "migraiac"
}
