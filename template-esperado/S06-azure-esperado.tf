# S06 (esperado) - Red/Seguridad: Network Security Group
# Equivalencia: aws_security_group -> azurerm_network_security_group (con security_rule)
resource "azurerm_resource_group" "main" {
  name     = "rg-migraiac-s06"
  location = "eastus"
}

resource "azurerm_network_security_group" "web" {
  name                = "nsg-migraiac-s06"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  security_rule {
    name                       = "AllowHTTP"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowSSH"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}
