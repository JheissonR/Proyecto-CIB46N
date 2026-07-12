# S09 (esperado) - Red: Virtual Network con salida a Internet
# Equivalencia: aws_vpc -> azurerm_virtual_network
#               aws_internet_gateway -> (Tipo II) en Azure la salida a Internet es implicita;
#               se modela con NAT Gateway o Public IP segun el caso. Aqui se usa NAT Gateway.
resource "azurerm_resource_group" "main" {
  name     = "rg-migraiac-s09"
  location = "eastus"
}

resource "azurerm_virtual_network" "main" {
  name                = "vnet-migraiac-s09"
  address_space       = ["10.2.0.0/16"]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_public_ip" "nat" {
  name                = "pip-nat-migraiac-s09"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_nat_gateway" "gw" {
  name                = "natgw-migraiac-s09"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}
