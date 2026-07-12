# S05 (esperado) - Almacenamiento: Managed Disk
# Equivalencia: aws_ebs_volume -> azurerm_managed_disk
resource "azurerm_resource_group" "main" {
  name     = "rg-migraiac-s05"
  location = "eastus"
}

resource "azurerm_managed_disk" "data" {
  name                 = "disk-migraiac-s05"
  location             = azurerm_resource_group.main.location
  resource_group_name  = azurerm_resource_group.main.name
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = 20

  tags = {
    Name = "migraiac-ebs-s05"
  }
}
