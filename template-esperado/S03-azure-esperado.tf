# S03 (esperado) - Red: Virtual Network
# Equivalencia: aws_vpc -> azurerm_virtual_network (+ resource group)
resource "azurerm_resource_group" "main" {
  name     = "rg-migraiac-s03"
  location = "eastus"
}

resource "azurerm_virtual_network" "main" {
  name                = "vnet-migraiac-s03"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  tags = {
    Name = "migraiac-vpc-s03"
  }
}
