# C10 (esperado) - BD alta disponibilidad: MySQL Flexible con replicas y secretos
resource "azurerm_resource_group" "main" {
  name     = "rg-migraiac-c10"
  location = "eastus"
}

resource "azurerm_virtual_network" "main" {
  name                = "vnet-migraiac-c10"
  address_space       = ["10.4.0.0/16"]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_subnet" "a" {
  name                 = "subnet-a-c10"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.4.1.0/24"]
}

resource "azurerm_subnet" "b" {
  name                 = "subnet-b-c10"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.4.2.0/24"]
}

resource "azurerm_network_security_group" "db" {
  name                = "nsg-db-c10"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_mysql_flexible_server" "primary" {
  name                   = "migraiac-mysql-c10"
  resource_group_name    = azurerm_resource_group.main.name
  location               = azurerm_resource_group.main.location
  administrator_login    = "adminuser"
  administrator_password = "ChangeMe123456!"
  sku_name               = "GP_Standard_D2ds_v4"
  version                = "8.0.21"
  high_availability {
    mode = "ZoneRedundant"
  }
}

resource "azurerm_mysql_flexible_server" "replica_a" {
  name                   = "migraiac-mysql-replica-a-c10"
  resource_group_name    = azurerm_resource_group.main.name
  location               = azurerm_resource_group.main.location
  create_mode            = "Replica"
  source_server_id       = azurerm_mysql_flexible_server.primary.id
  sku_name               = "GP_Standard_D2ds_v4"
  version                = "8.0.21"
}

resource "azurerm_mysql_flexible_server" "replica_b" {
  name                   = "migraiac-mysql-replica-b-c10"
  resource_group_name    = azurerm_resource_group.main.name
  location               = "westus"
  create_mode            = "Replica"
  source_server_id       = azurerm_mysql_flexible_server.primary.id
  sku_name               = "GP_Standard_D2ds_v4"
  version                = "8.0.21"
}

data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "main" {
  name                = "kv-migraiac-c10"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"
}

resource "azurerm_key_vault_secret" "db" {
  name         = "db-credentials-c10"
  value        = jsonencode({ username = "adminuser", password = "ChangeMe123456!" })
  key_vault_id = azurerm_key_vault.main.id
}

resource "azurerm_monitor_action_group" "alerts" {
  name                = "ag-migraiac-c10"
  resource_group_name = azurerm_resource_group.main.name
  short_name          = "migraiac"
}

resource "azurerm_monitor_metric_alert" "cpu" {
  name                = "alert-db-cpu-c10"
  resource_group_name = azurerm_resource_group.main.name
  scopes              = [azurerm_mysql_flexible_server.primary.id]
  criteria {
    metric_namespace = "Microsoft.DBforMySQL/flexibleServers"
    metric_name      = "cpu_percent"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 80
  }
  action {
    action_group_id = azurerm_monitor_action_group.alerts.id
  }
}
