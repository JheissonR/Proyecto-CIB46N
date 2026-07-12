# M09 (esperado) - Red: VNet con subredes publica/privada y NAT Gateway
# aws_vpc->vnet ; aws_subnet->subnet ; aws_internet_gateway->(implicito) ;
# aws_eip->public_ip ; aws_nat_gateway->nat_gateway ; aws_route_table->route_table ;
# aws_route_table_association->subnet_route_table_association
resource "azurerm_resource_group" "main" {
  name     = "rg-migraiac-m09"
  location = "eastus"
}

resource "azurerm_virtual_network" "main" {
  name                = "vnet-migraiac-m09"
  address_space       = ["10.4.0.0/16"]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_subnet" "public" {
  name                 = "subnet-public-m09"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.4.1.0/24"]
}

resource "azurerm_subnet" "private" {
  name                 = "subnet-private-m09"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.4.10.0/24"]
}

resource "azurerm_public_ip" "nat" {
  name                = "pip-nat-migraiac-m09"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_nat_gateway" "main" {
  name                = "natgw-migraiac-m09"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_nat_gateway_public_ip_association" "main" {
  nat_gateway_id       = azurerm_nat_gateway.main.id
  public_ip_address_id = azurerm_public_ip.nat.id
}

resource "azurerm_subnet_nat_gateway_association" "private" {
  subnet_id      = azurerm_subnet.private.id
  nat_gateway_id = azurerm_nat_gateway.main.id
}

resource "azurerm_route_table" "private" {
  name                = "rt-private-migraiac-m09"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_subnet_route_table_association" "private" {
  subnet_id      = azurerm_subnet.private.id
  route_table_id = azurerm_route_table.private.id
}
