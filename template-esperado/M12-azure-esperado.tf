# M12 (esperado) - API REST: API Management con Function App
# aws_lambda_function->linux_function_app ; aws_iam_role->identidad administrada ;
# aws_api_gateway_rest_api->api_management ; aws_api_gateway_resource/method/integration->api+operation ;
# aws_lambda_permission->(backend binding)
resource "azurerm_resource_group" "main" {
  name     = "rg-migraiac-m12"
  location = "eastus"
}

resource "azurerm_storage_account" "fn" {
  name                     = "migraiacfnm12"
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_service_plan" "fn" {
  name                = "plan-migraiac-m12"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  os_type             = "Linux"
  sku_name            = "Y1"
}

resource "azurerm_linux_function_app" "api" {
  name                       = "func-migraiac-m12"
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

resource "azurerm_api_management" "main" {
  name                = "apim-migraiac-m12"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  publisher_name      = "MIGRAIAC"
  publisher_email     = "admin@migraiac.dev"
  sku_name            = "Consumption_0"
}

resource "azurerm_api_management_api" "items" {
  name                = "items-api-m12"
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
