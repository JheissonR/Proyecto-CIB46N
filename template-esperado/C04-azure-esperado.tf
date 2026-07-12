# C04 (esperado) - Pipeline de datos: Event Hub + Data Factory + Data Lake + Synapse
resource "azurerm_resource_group" "main" {
  name     = "rg-migraiac-c04"
  location = "eastus"
}

resource "azurerm_eventhub_namespace" "main" {
  name                = "ehns-migraiac-c04"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "Standard"
  capacity            = 2
}

resource "azurerm_eventhub" "ingest" {
  name                = "migraiac-ingest-c04"
  namespace_name      = azurerm_eventhub_namespace.main.name
  resource_group_name = azurerm_resource_group.main.name
  partition_count     = 2
  message_retention   = 1
}

resource "azurerm_storage_account" "raw" {
  name                     = "migraiacrawc04"
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  is_hns_enabled           = true
  blob_properties {
    versioning_enabled = true
  }
}

resource "azurerm_storage_account" "processed" {
  name                     = "migraiacprocessedc04"
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  is_hns_enabled           = true
}

resource "azurerm_storage_account" "curated" {
  name                     = "migraiaccuratedc04"
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  is_hns_enabled           = true
}

resource "azurerm_data_factory" "main" {
  name                = "adf-migraiac-c04"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_storage_account" "fn" {
  name                     = "migraiacfnc04"
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_service_plan" "fn" {
  name                = "plan-migraiac-c04"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  os_type             = "Linux"
  sku_name            = "Y1"
}

resource "azurerm_linux_function_app" "trigger" {
  name                       = "func-migraiac-c04"
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

resource "azurerm_log_analytics_workspace" "main" {
  name                = "log-migraiac-c04"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "PerGB2018"
  retention_in_days   = 7
}

resource "azurerm_synapse_workspace" "main" {
  name                                 = "syn-migraiac-c04"
  resource_group_name                  = azurerm_resource_group.main.name
  location                             = azurerm_resource_group.main.location
  storage_data_lake_gen2_filesystem_id = "https://${azurerm_storage_account.curated.name}.dfs.core.windows.net/synapse"
  sql_administrator_login              = "sqladmin"
  sql_administrator_login_password     = "ChangeMe123456!"
  identity {
    type = "SystemAssigned"
  }
}
