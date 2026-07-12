# C08 (esperado) - Event-driven: Logic App + Function App + Service Bus + Event Grid
resource "azurerm_resource_group" "main" {
  name     = "rg-migraiac-c08"
  location = "eastus"
}

resource "azurerm_cosmosdb_account" "orders" {
  name                = "cosmos-migraiac-c08"
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

resource "azurerm_servicebus_namespace" "main" {
  name                = "sb-migraiac-c08"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "Standard"
}

resource "azurerm_servicebus_queue" "orders" {
  name         = "migraiac-orders-c08"
  namespace_id = azurerm_servicebus_namespace.main.id
}

resource "azurerm_servicebus_queue" "dlq" {
  name         = "migraiac-dlq-c08"
  namespace_id = azurerm_servicebus_namespace.main.id
}

resource "azurerm_eventgrid_topic" "orders" {
  name                = "egt-orders-c08"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_storage_account" "fn" {
  name                     = "migraiacfnc08"
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_service_plan" "fn" {
  name                = "plan-migraiac-c08"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  os_type             = "Linux"
  sku_name            = "Y1"
}

resource "azurerm_linux_function_app" "process" {
  name                       = "func-migraiac-c08"
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
      node_version = "18"
    }
  }
}

resource "azurerm_logic_app_workflow" "order_flow" {
  name                = "logic-order-flow-c08"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_monitor_action_group" "notifications" {
  name                = "ag-migraiac-c08"
  resource_group_name = azurerm_resource_group.main.name
  short_name          = "migraiac"
}

resource "azurerm_log_analytics_workspace" "main" {
  name                = "log-migraiac-c08"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "PerGB2018"
  retention_in_days   = 7
}
