# C13 (esperado) - Red hibrida: Virtual WAN con hub, VNets y VPN
# Nota (Tipo II): AWS Transit Gateway -> Azure Virtual WAN + Virtual Hub.
resource "azurerm_resource_group" "main" {
  name     = "rg-migraiac-c13"
  location = "eastus"
}

resource "azurerm_virtual_wan" "main" {
  name                = "vwan-migraiac-c13"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
}

resource "azurerm_virtual_hub" "main" {
  name                = "hub-migraiac-c13"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  virtual_wan_id      = azurerm_virtual_wan.main.id
  address_prefix      = "10.100.0.0/24"
}

resource "azurerm_virtual_network" "prod" {
  name                = "vnet-prod-c13"
  address_space       = ["10.30.0.0/16"]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_virtual_network" "dev" {
  name                = "vnet-dev-c13"
  address_space       = ["10.31.0.0/16"]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_virtual_network" "shared" {
  name                = "vnet-shared-c13"
  address_space       = ["10.32.0.0/16"]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_virtual_hub_connection" "prod" {
  name                      = "conn-prod-c13"
  virtual_hub_id            = azurerm_virtual_hub.main.id
  remote_virtual_network_id = azurerm_virtual_network.prod.id
}

resource "azurerm_virtual_hub_connection" "dev" {
  name                      = "conn-dev-c13"
  virtual_hub_id            = azurerm_virtual_hub.main.id
  remote_virtual_network_id = azurerm_virtual_network.dev.id
}

resource "azurerm_virtual_hub_connection" "shared" {
  name                      = "conn-shared-c13"
  virtual_hub_id            = azurerm_virtual_hub.main.id
  remote_virtual_network_id = azurerm_virtual_network.shared.id
}

resource "azurerm_vpn_gateway" "main" {
  name                = "vpngw-migraiac-c13"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  virtual_hub_id      = azurerm_virtual_hub.main.id
}

resource "azurerm_vpn_site" "onprem" {
  name                = "site-onprem-c13"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  virtual_wan_id      = azurerm_virtual_wan.main.id
  link {
    name       = "onprem-link"
    ip_address = "203.0.113.1"
  }
}

resource "azurerm_storage_account" "flowlogs" {
  name                     = "migraiacflowlogsc13"
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_network_watcher" "main" {
  name                = "nw-migraiac-c13"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}
