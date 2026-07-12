# M04 (esperado) - Serverless: Function App con Cosmos DB y Storage Queue
# aws_lambda_function->linux_function_app ; aws_iam_role(+policy)->identidad administrada ;
# aws_dynamodb_table->cosmosdb (table) ; aws_cloudwatch_log_group->log_analytics_workspace ;
# aws_sqs_queue->storage_queue ; aws_lambda_event_source_mapping->(binding de la function)
resource "azurerm_resource_group" "main" {
  name     = "rg-migraiac-m04"
  location = "eastus"
}

resource "azurerm_storage_account" "fn" {
  name                     = "migraiacfnm04"
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_queue" "events" {
  name                 = "migraiac-events-m04"
  storage_account_name = azurerm_storage_account.fn.name
}

resource "azurerm_cosmosdb_account" "main" {
  name                = "cosmos-migraiac-m04"
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

resource "azurerm_cosmosdb_table" "data" {
  name                = "migraiac-data-m04"
  resource_group_name = azurerm_resource_group.main.name
  account_name        = azurerm_cosmosdb_account.main.name
}

resource "azurerm_log_analytics_workspace" "fn" {
  name                = "log-migraiac-m04"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "PerGB2018"
  retention_in_days   = 7
}

resource "azurerm_service_plan" "fn" {
  name                = "plan-migraiac-m04"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  os_type             = "Linux"
  sku_name            = "Y1"
}

resource "azurerm_linux_function_app" "fn" {
  name                       = "func-migraiac-m04"
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
