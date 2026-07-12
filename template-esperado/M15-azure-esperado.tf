# M15 (esperado) - BD con monitoreo: PostgreSQL con alertas de metricas
# aws_vpc->vnet ; aws_subnet->subnet ; aws_db_subnet_group->(delegacion) ;
# aws_db_instance(postgres,multi_az)->postgresql_flexible_server(zone_redundant) ;
# aws_sns_topic->monitor_action_group ; aws_cloudwatch_metric_alarm->monitor_metric_alert
resource "azurerm_resource_group" "main" {
  name     = "rg-migraiac-m15"
  location = "eastus"
}

resource "azurerm_virtual_network" "main" {
  name                = "vnet-migraiac-m15"
  address_space       = ["10.7.0.0/16"]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_subnet" "a" {
  name                 = "subnet-a-m15"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.7.1.0/24"]
}

resource "azurerm_subnet" "b" {
  name                 = "subnet-b-m15"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.7.2.0/24"]
}

resource "azurerm_postgresql_flexible_server" "main" {
  name                   = "migraiac-pg-m15"
  resource_group_name    = azurerm_resource_group.main.name
  location               = azurerm_resource_group.main.location
  version                = "15"
  administrator_login    = "adminuser"
  administrator_password = "ChangeMe123!"
  storage_mb             = 32768
  sku_name               = "GP_Standard_D2s_v3"
  zone                   = "1"
  high_availability {
    mode = "ZoneRedundant"
  }
}

resource "azurerm_monitor_action_group" "alerts" {
  name                = "ag-migraiac-m15"
  resource_group_name = azurerm_resource_group.main.name
  short_name          = "migraiac"
}

resource "azurerm_monitor_metric_alert" "cpu" {
  name                = "alert-db-cpu-m15"
  resource_group_name = azurerm_resource_group.main.name
  scopes              = [azurerm_postgresql_flexible_server.main.id]
  description         = "Alerta cuando la CPU supera el 80%"

  criteria {
    metric_namespace = "Microsoft.DBforPostgreSQL/flexibleServers"
    metric_name      = "cpu_percent"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 80
  }

  action {
    action_group_id = azurerm_monitor_action_group.alerts.id
  }
}

resource "azurerm_monitor_metric_alert" "storage" {
  name                = "alert-db-storage-m15"
  resource_group_name = azurerm_resource_group.main.name
  scopes              = [azurerm_postgresql_flexible_server.main.id]
  description         = "Alerta cuando el almacenamiento libre es bajo"

  criteria {
    metric_namespace = "Microsoft.DBforPostgreSQL/flexibleServers"
    metric_name      = "storage_percent"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 90
  }

  action {
    action_group_id = azurerm_monitor_action_group.alerts.id
  }
}
