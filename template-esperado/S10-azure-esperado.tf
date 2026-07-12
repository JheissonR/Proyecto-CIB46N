# S10 (esperado) - Computo serverless: Function App
# Equivalencia: aws_lambda_function -> azurerm_linux_function_app
#               aws_iam_role -> identidad administrada (managed identity) de la Function App
#               (Azure requiere ademas Service Plan y Storage Account de soporte)
resource "azurerm_resource_group" "main" {
  name     = "rg-migraiac-s10"
  location = "eastus"
}

resource "azurerm_storage_account" "fn" {
  name                     = "migraiacfns10"
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_service_plan" "fn" {
  name                = "plan-migraiac-s10"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  os_type             = "Linux"
  sku_name            = "Y1"
}

resource "azurerm_linux_function_app" "fn" {
  name                       = "func-migraiac-s10"
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
