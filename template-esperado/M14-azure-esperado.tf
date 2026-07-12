# M14 (esperado) - Cache: Azure Cache for Redis con VM
# aws_vpc->vnet ; aws_subnet->subnet ; aws_elasticache_subnet_group->(subred) ;
# aws_security_group->NSG ; aws_elasticache_cluster(redis)->redis_cache ; aws_instance->linux_vm
resource "azurerm_resource_group" "main" {
  name     = "rg-migraiac-m14"
  location = "eastus"
}

resource "azurerm_virtual_network" "main" {
  name                = "vnet-migraiac-m14"
  address_space       = ["10.6.0.0/16"]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_subnet" "a" {
  name                 = "subnet-a-m14"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.6.1.0/24"]
}

resource "azurerm_network_security_group" "cache" {
  name                = "nsg-migraiac-cache-m14"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  security_rule {
    name                       = "AllowRedis"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "6379"
    source_address_prefix      = "10.6.0.0/16"
    destination_address_prefix = "*"
  }
}

resource "azurerm_redis_cache" "redis" {
  name                = "redis-migraiac-m14"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  capacity            = 0
  family              = "C"
  sku_name            = "Basic"
}

resource "azurerm_network_interface" "app" {
  name                = "nic-migraiac-app-m14"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.a.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "app" {
  name                  = "vm-migraiac-app-m14"
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
