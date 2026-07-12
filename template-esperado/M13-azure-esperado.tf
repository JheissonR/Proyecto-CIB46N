# M13 (esperado) - Streaming: Event Hub con Function App y Storage
# aws_kinesis_stream->eventhub(+namespace) ; aws_s3_bucket->storage_account ;
# aws_lambda_function->linux_function_app ; aws_iam_role(+policy)->identidad administrada ;
# aws_cloudwatch_log_group->log_analytics_workspace ; aws_lambda_event_source_mapping->(binding)
resource "azurerm_resource_group" "main" {
  name     = "rg-migraiac-m13"
  location = "eastus"
}

resource "azurerm_eventhub_namespace" "main" {
  name                = "ehns-migraiac-m13"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "Standard"
  capacity            = 1
}

resource "azurerm_eventhub" "events" {
  name                = "migraiac-stream-m13"
  namespace_name      = azurerm_eventhub_namespace.main.name
  resource_group_name = azurerm_resource_group.main.name
  partition_count     = 1
  message_retention   = 1
}

resource "azurerm_storage_account" "data" {
  name                     = "migraiacdatam13"
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_log_analytics_workspace" "main" {
  name                = "log-migraiac-m13"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "PerGB2018"
  retention_in_days   = 7
}

resource "azurerm_service_plan" "fn" {
  name                = "plan-migraiac-m13"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  os_type             = "Linux"
  sku_name            = "Y1"
}

resource "azurerm_linux_function_app" "processor" {
  name                       = "func-migraiac-m13"
  resource_group_name        = azurerm_resource_group.main.name
  location                   = azurerm_resource_group.main.location
  storage_account_name       = azurerm_storage_account.data.name
  storage_account_access_key = azurerm_storage_account.data.primary_access_key
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
