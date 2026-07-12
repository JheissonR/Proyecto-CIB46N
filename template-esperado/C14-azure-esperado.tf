# C14 (esperado) - Batch HPC: Azure Batch con Files compartido y ACR
resource "azurerm_resource_group" "main" {
  name     = "rg-migraiac-c14"
  location = "eastus"
}

resource "azurerm_virtual_network" "main" {
  name                = "vnet-migraiac-c14"
  address_space       = ["10.5.0.0/16"]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_subnet" "batch" {
  name                 = "subnet-batch-c14"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.5.1.0/24"]
}

resource "azurerm_network_security_group" "batch" {
  name                = "nsg-batch-c14"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_storage_account" "shared" {
  name                     = "migraiacsharedc14"
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_share" "shared" {
  name                 = "migraiac-shared-c14"
  storage_account_name = azurerm_storage_account.shared.name
  quota                = 100
}

resource "azurerm_storage_account" "input" {
  name                     = "migraiacinputc14"
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_account" "output" {
  name                     = "migraiacoutputc14"
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_container_registry" "job" {
  name                = "migraiacacrc14"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  sku                 = "Basic"
}

resource "azurerm_batch_account" "main" {
  name                = "migraiacbatchc14"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
}

resource "azurerm_batch_pool" "main" {
  name                = "migraiac-pool-c14"
  resource_group_name = azurerm_resource_group.main.name
  account_name        = azurerm_batch_account.main.name
  display_name        = "Compute Pool"
  vm_size             = "Standard_D2s_v3"
  node_agent_sku_id   = "batch.node.ubuntu 20.04"

  fixed_scale {
    target_dedicated_nodes = 2
  }

  storage_image_reference {
    publisher = "canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts"
    version   = "latest"
  }
}

resource "azurerm_log_analytics_workspace" "main" {
  name                = "log-migraiac-c14"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "PerGB2018"
  retention_in_days   = 7
}

resource "azurerm_monitor_action_group" "job_status" {
  name                = "ag-migraiac-c14"
  resource_group_name = azurerm_resource_group.main.name
  short_name          = "migraiac"
}
