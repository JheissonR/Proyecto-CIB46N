# M08 (esperado) - Mensajeria: Service Bus con Function App
# aws_sns_topic->servicebus_topic ; aws_sqs_queue->servicebus_queue ;
# aws_sns_topic_subscription->servicebus_subscription ; aws_lambda_function->linux_function_app ;
# aws_iam_role->identidad administrada
resource "azurerm_resource_group" "main" {
  name     = "rg-migraiac-m08"
  location = "eastus"
}

resource "azurerm_servicebus_namespace" "main" {
  name                = "sb-migraiac-m08"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "Standard"
}

resource "azurerm_servicebus_topic" "events" {
  name         = "migraiac-events-m08"
  namespace_id = azurerm_servicebus_namespace.main.id
}

resource "azurerm_servicebus_queue" "worker" {
  name         = "migraiac-worker-m08"
  namespace_id = azurerm_servicebus_namespace.main.id
}

resource "azurerm_servicebus_subscription" "sqs" {
  name               = "worker-sub-m08"
  topic_id           = azurerm_servicebus_topic.events.id
  max_delivery_count = 10
}

resource "azurerm_storage_account" "fn" {
  name                     = "migraiacfnm08"
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_service_plan" "fn" {
  name                = "plan-migraiac-m08"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  os_type             = "Linux"
  sku_name            = "Y1"
}

resource "azurerm_linux_function_app" "processor" {
  name                       = "func-migraiac-m08"
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
