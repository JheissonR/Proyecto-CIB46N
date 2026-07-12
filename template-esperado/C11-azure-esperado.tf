# C11 (esperado) - CI/CD: ACR Tasks + Storage de artefactos + Log Analytics
# Nota (Tipo II): AWS CodePipeline/CodeBuild no tienen equivalente 1:1 en Terraform Azure.
# Se modela con ACR (build tasks), Storage de artefactos, identidad administrada y notificaciones.
resource "azurerm_resource_group" "main" {
  name     = "rg-migraiac-c11"
  location = "eastus"
}

resource "azurerm_storage_account" "artifacts" {
  name                            = "migraiacartifactsc11"
  resource_group_name             = azurerm_resource_group.main.name
  location                        = azurerm_resource_group.main.location
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false
  blob_properties {
    versioning_enabled = true
  }
}

resource "azurerm_container_registry" "app" {
  name                = "migraiacacrc11"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  sku                 = "Standard"
}

resource "azurerm_user_assigned_identity" "build" {
  name                = "id-build-c11"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
}

resource "azurerm_user_assigned_identity" "deploy" {
  name                = "id-deploy-c11"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
}

resource "azurerm_role_assignment" "build_acr" {
  scope                = azurerm_container_registry.app.id
  role_definition_name = "AcrPush"
  principal_id         = azurerm_user_assigned_identity.build.principal_id
}

resource "azurerm_role_assignment" "build_storage" {
  scope                = azurerm_storage_account.artifacts.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_user_assigned_identity.build.principal_id
}

resource "azurerm_container_registry_task" "build" {
  name                  = "build-task-c11"
  container_registry_id = azurerm_container_registry.app.id
  platform {
    os = "Linux"
  }
  docker_step {
    dockerfile_path      = "Dockerfile"
    context_path         = "https://github.com/migraiac/app"
    context_access_token = "placeholder"
    image_names          = ["app:latest"]
  }
}

resource "azurerm_log_analytics_workspace" "main" {
  name                = "log-migraiac-c11"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "PerGB2018"
  retention_in_days   = 7
}

resource "azurerm_monitor_action_group" "pipeline" {
  name                = "ag-pipeline-c11"
  resource_group_name = azurerm_resource_group.main.name
  short_name          = "pipeline"
}
