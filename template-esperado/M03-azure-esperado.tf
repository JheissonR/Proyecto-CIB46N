# M03 (esperado) - Computo + BD: VM con Azure Database for MySQL
# aws_vpc->vnet ; aws_subnet->subnet ; aws_db_subnet_group->(delegacion de subred) ;
# aws_security_group->NSG ; aws_db_instance(mysql)->mysql_flexible_server ; aws_instance->linux_vm
resource "azurerm_resource_group" "main" {
  name     = "rg-migraiac-m03"
  location = "eastus"
}

resource "azurerm_virtual_network" "main" {
  name                = "vnet-migraiac-m03"
  address_space       = ["10.1.0.0/16"]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_subnet" "app" {
  name                 = "subnet-app-m03"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.1.1.0/24"]
}

resource "azurerm_subnet" "db" {
  name                 = "subnet-db-m03"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.1.2.0/24"]
}

resource "azurerm_network_security_group" "db" {
  name                = "nsg-migraiac-db-m03"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  security_rule {
    name                       = "AllowMySQL"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3306"
    source_address_prefix      = "10.1.0.0/16"
    destination_address_prefix = "*"
  }
}

resource "azurerm_mysql_flexible_server" "main" {
  name                   = "migraiac-db-m03"
  resource_group_name    = azurerm_resource_group.main.name
  location               = azurerm_resource_group.main.location
  administrator_login    = "adminuser"
  administrator_password = "ChangeMe123!"
  sku_name               = "B_Standard_B1ms"
  version                = "8.0.21"
}

resource "azurerm_network_interface" "app" {
  name                = "nic-migraiac-app-m03"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.app.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "app" {
  name                  = "vm-migraiac-app-m03"
  resource_group_name   = azurerm_resource_group.main.name
  location              = azurerm_resource_group.main.location
  size                  = "Standard_B1ms"
  admin_username        = "azureuser"
  network_interface_ids = [azurerm_network_interface.app.id]

  admin_ssh_key {
    username   = "azureuser"
    public_key = file("~/.ssh/id_rsa.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
}
