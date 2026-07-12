# M11 (esperado) - Kubernetes: Azure Kubernetes Service (AKS)
# aws_vpc->vnet ; aws_subnet->subnet ; aws_iam_role(cluster/node)->identidad administrada ;
# aws_eks_cluster+aws_eks_node_group->kubernetes_cluster (con default_node_pool)
resource "azurerm_resource_group" "main" {
  name     = "rg-migraiac-m11"
  location = "eastus"
}

resource "azurerm_virtual_network" "main" {
  name                = "vnet-migraiac-m11"
  address_space       = ["10.5.0.0/16"]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_subnet" "aks" {
  name                 = "subnet-aks-m11"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.5.1.0/24"]
}

resource "azurerm_kubernetes_cluster" "main" {
  name                = "aks-migraiac-m11"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  dns_prefix          = "migraiacm11"

  default_node_pool {
    name           = "default"
    node_count     = 2
    vm_size        = "Standard_D2_v2"
    vnet_subnet_id = azurerm_subnet.aks.id
  }

  identity {
    type = "SystemAssigned"
  }
}
