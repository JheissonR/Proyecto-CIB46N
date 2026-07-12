# M05 (esperado) - Computo escalable: Virtual Machine Scale Set
# aws_vpc->vnet ; aws_subnet->subnet ; aws_security_group->NSG ;
# aws_launch_template+aws_autoscaling_group->linux_virtual_machine_scale_set
resource "azurerm_resource_group" "main" {
  name     = "rg-migraiac-m05"
  location = "eastus"
}

resource "azurerm_virtual_network" "main" {
  name                = "vnet-migraiac-m05"
  address_space       = ["10.2.0.0/16"]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_subnet" "a" {
  name                 = "subnet-a-m05"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.2.1.0/24"]
}

resource "azurerm_network_security_group" "app" {
  name                = "nsg-migraiac-app-m05"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_linux_virtual_machine_scale_set" "app" {
  name                = "vmss-migraiac-m05"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  sku                 = "Standard_B1s"
  instances           = 2
  admin_username      = "azureuser"

  admin_ssh_key {
    username   = "azureuser"
    public_key = file("~/.ssh/id_rsa.pub")
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  network_interface {
    name    = "nic-vmss-m05"
    primary = true
    ip_configuration {
      name      = "internal"
      primary   = true
      subnet_id = azurerm_subnet.a.id
    }
  }
}
