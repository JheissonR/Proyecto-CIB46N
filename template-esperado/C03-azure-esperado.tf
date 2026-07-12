# C03 (esperado) - Microservicios: Container Apps con ACR y balanceo
resource "azurerm_resource_group" "main" {
  name     = "rg-migraiac-c03"
  location = "eastus"
}

resource "azurerm_virtual_network" "main" {
  name                = "vnet-migraiac-c03"
  address_space       = ["10.1.0.0/16"]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_subnet" "apps" {
  name                 = "subnet-apps-c03"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.1.0.0/23"]
}

resource "azurerm_container_registry" "svc_a" {
  name                = "migraiacacrac03"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  sku                 = "Basic"
}

resource "azurerm_container_registry" "svc_b" {
  name                = "migraiacacrbc03"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  sku                 = "Basic"
}

resource "azurerm_log_analytics_workspace" "main" {
  name                = "log-migraiac-c03"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "PerGB2018"
  retention_in_days   = 7
}

resource "azurerm_container_app_environment" "main" {
  name                       = "cae-migraiac-c03"
  location                   = azurerm_resource_group.main.location
  resource_group_name        = azurerm_resource_group.main.name
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id
  infrastructure_subnet_id   = azurerm_subnet.apps.id
}

resource "azurerm_container_app" "svc_a" {
  name                         = "app-svc-a-c03"
  container_app_environment_id = azurerm_container_app_environment.main.id
  resource_group_name          = azurerm_resource_group.main.name
  revision_mode                = "Single"
  template {
    container {
      name   = "svc-a"
      image  = "${azurerm_container_registry.svc_a.login_server}/svc-a:latest"
      cpu    = 0.25
      memory = "0.5Gi"
    }
    min_replicas = 2
  }
  ingress {
    external_enabled = true
    target_port      = 80
    traffic_weight {
      percentage      = 100
      latest_revision = true
    }
  }
}

resource "azurerm_container_app" "svc_b" {
  name                         = "app-svc-b-c03"
  container_app_environment_id = azurerm_container_app_environment.main.id
  resource_group_name          = azurerm_resource_group.main.name
  revision_mode                = "Single"
  template {
    container {
      name   = "svc-b"
      image  = "${azurerm_container_registry.svc_b.login_server}/svc-b:latest"
      cpu    = 0.25
      memory = "0.5Gi"
    }
    min_replicas = 2
  }
  ingress {
    external_enabled = false
    target_port      = 8080
    traffic_weight {
      percentage      = 100
      latest_revision = true
    }
  }
}
