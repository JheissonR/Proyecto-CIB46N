# C05 (esperado) - Red avanzada: dos VNet con peering bidireccional
resource "azurerm_resource_group" "main" {
  name     = "rg-migraiac-c05"
  location = "eastus"
}

resource "azurerm_virtual_network" "app" {
  name                = "vnet-app-c05"
  address_space       = ["10.10.0.0/16"]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_virtual_network" "data" {
  name                = "vnet-data-c05"
  address_space       = ["10.20.0.0/16"]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_subnet" "app_a" {
  name                 = "subnet-app-a-c05"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.app.name
  address_prefixes     = ["10.10.1.0/24"]
}

resource "azurerm_subnet" "app_b" {
  name                 = "subnet-app-b-c05"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.app.name
  address_prefixes     = ["10.10.2.0/24"]
}

resource "azurerm_subnet" "data_a" {
  name                 = "subnet-data-a-c05"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.data.name
  address_prefixes     = ["10.20.1.0/24"]
}

resource "azurerm_subnet" "data_b" {
  name                 = "subnet-data-b-c05"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.data.name
  address_prefixes     = ["10.20.2.0/24"]
}

resource "azurerm_virtual_network_peering" "app_to_data" {
  name                      = "app-to-data-c05"
  resource_group_name       = azurerm_resource_group.main.name
  virtual_network_name      = azurerm_virtual_network.app.name
  remote_virtual_network_id = azurerm_virtual_network.data.id
  allow_forwarded_traffic   = true
}

resource "azurerm_virtual_network_peering" "data_to_app" {
  name                      = "data-to-app-c05"
  resource_group_name       = azurerm_resource_group.main.name
  virtual_network_name      = azurerm_virtual_network.data.name
  remote_virtual_network_id = azurerm_virtual_network.app.id
  allow_forwarded_traffic   = true
}

resource "azurerm_network_security_group" "app" {
  name                = "nsg-app-c05"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  security_rule {
    name                       = "AllowHTTPS"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_security_group" "data" {
  name                = "nsg-data-c05"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  security_rule {
    name                       = "AllowPostgres"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5432"
    source_address_prefix      = "10.10.0.0/16"
    destination_address_prefix = "*"
  }
}
