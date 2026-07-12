# M07 (esperado) - Contenedores: Azure Container Apps
# aws_ecr_repository->container_registry ; aws_ecs_cluster->container_app_environment ;
# aws_iam_role->identidad administrada ; aws_cloudwatch_log_group->log_analytics_workspace ;
# aws_ecs_task_definition+aws_ecs_service->container_app
resource "azurerm_resource_group" "main" {
  name     = "rg-migraiac-m07"
  location = "eastus"
}

resource "azurerm_container_registry" "app" {
  name                = "migraiacacrm07"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  sku                 = "Basic"
  admin_enabled       = false
}

resource "azurerm_log_analytics_workspace" "main" {
  name                = "log-migraiac-m07"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "PerGB2018"
  retention_in_days   = 7
}

resource "azurerm_container_app_environment" "main" {
  name                       = "cae-migraiac-m07"
  location                   = azurerm_resource_group.main.location
  resource_group_name        = azurerm_resource_group.main.name
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id
}

resource "azurerm_container_app" "app" {
  name                         = "app-migraiac-m07"
  container_app_environment_id = azurerm_container_app_environment.main.id
  resource_group_name          = azurerm_resource_group.main.name
  revision_mode                = "Single"

  identity {
    type = "SystemAssigned"
  }

  template {
    container {
      name   = "app"
      image  = "${azurerm_container_registry.app.login_server}/app:latest"
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
