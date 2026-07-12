# S12 (esperado) - Red: Virtual Network con tabla de rutas
# Equivalencia: aws_vpc -> azurerm_virtual_network ; aws_route_table -> azurerm_route_table
resource "azurerm_resource_group" "main" {
  name     = "rg-migraiac-s12"
  location = "eastus"
}

resource "azurerm_virtual_network" "main" {
  name                = "vnet-migraiac-s12"
  address_space       = ["10.3.0.0/16"]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_route_table" "public" {
  name                = "rt-migraiac-s12"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}
