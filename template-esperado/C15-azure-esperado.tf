# C15 (esperado) - App empresarial: AKS + PostgreSQL + Redis + observabilidad
resource "azurerm_resource_group" "main" {
  name     = "rg-migraiac-c15"
  location = "eastus"
}

resource "azurerm_virtual_network" "main" {
  name                = "vnet-migraiac-c15"
  address_space       = ["10.6.0.0/16"]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_subnet" "public" {
  name                 = "subnet-public-c15"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.6.1.0/24"]
}

resource "azurerm_subnet" "private_a" {
  name                 = "subnet-private-a-c15"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.6.11.0/24"]
}

resource "azurerm_subnet" "private_b" {
  name                 = "subnet-private-b-c15"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.6.12.0/24"]
}

resource "azurerm_public_ip" "nat" {
  name                = "pip-nat-c15"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_nat_gateway" "main" {
  name                = "natgw-migraiac-c15"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_network_security_group" "app" {
  name                = "nsg-app-c15"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_network_security_group" "data" {
  name                = "nsg-data-c15"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_postgresql_flexible_server" "main" {
  name                   = "migraiac-pg-c15"
  resource_group_name    = azurerm_resource_group.main.name
  location               = azurerm_resource_group.main.location
  version                = "15"
  administrator_login    = "adminuser"
  administrator_password = "ChangeMe123!"
  storage_mb             = 51200
  sku_name               = "GP_Standard_D2s_v3"
  high_availability {
    mode = "ZoneRedundant"
  }
}

resource "azurerm_redis_cache" "main" {
  name                = "redis-migraiac-c15"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  capacity            = 1
  family              = "C"
  sku_name            = "Standard"
}

resource "azurerm_kubernetes_cluster" "main" {
  name                = "aks-migraiac-c15"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  dns_prefix          = "migraiacc15"

  default_node_pool {
    name           = "default"
    node_count     = 2
    vm_size        = "Standard_D2_v2"
    vnet_subnet_id = azurerm_subnet.private_a.id
  }

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_log_analytics_workspace" "main" {
  name                = "log-migraiac-c15"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "PerGB2018"
  retention_in_days   = 14
}

resource "azurerm_monitor_action_group" "alerts" {
  name                = "ag-migraiac-c15"
  resource_group_name = azurerm_resource_group.main.name
  short_name          = "migraiac"
}

resource "azurerm_monitor_metric_alert" "db_cpu" {
  name                = "alert-db-cpu-c15"
  resource_group_name = azurerm_resource_group.main.name
  scopes              = [azurerm_postgresql_flexible_server.main.id]
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
