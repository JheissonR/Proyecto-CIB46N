# S04 (esperado) - Red: Virtual Network con subred
# Equivalencia: aws_vpc -> azurerm_virtual_network ; aws_subnet -> azurerm_subnet
resource "azurerm_resource_group" "main" {
  name     = "rg-migraiac-s04"
  location = "eastus"
}

resource "azurerm_virtual_network" "main" {
  name                = "vnet-migraiac-s04"
  address_space       = ["10.1.0.0/16"]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_subnet" "public" {
  name                 = "subnet-public-s04"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.1.1.0/24"]
}
