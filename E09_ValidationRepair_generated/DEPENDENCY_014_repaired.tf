provider "azurerm" {
  features {}
}

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group"
}

variable "location" {
  type        = string
  description = "Location of the resource group"
}

variable "virtual_network_name" {
  type        = string
  description = "Name of the virtual network"
}

variable "subnet_name" {
  type        = string
  description = "Name of the subnet"
}

variable "aks_cluster_name" {
  type        = string
  description = "Name of the AKS cluster"
}

variable "node_pool_name" {
  type        = string
  description = "Name of the node pool"
}

variable "node_count" {
  type        = number
  description = "Number of nodes in the node pool"
}

variable "vm_size" {
  type        = string
  description = "Size of the virtual machines in the node pool"
}

resource "azurerm_resource_group" "example" {
  name     = var.resource_group_name
  location = var.location
  tags = {
    Environment = "example"
  }
}

resource "azurerm_virtual_network" "example" {
  name                = var.virtual_network_name
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  tags = {
    Environment = "example"
  }
}

resource "azurerm_subnet" "example" {
  name                 = var.subnet_name
  resource_group_name = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.example.name
  address_prefixes     = ["10.0.1.0/24"]
  tags = {
    Environment = "example"
  }
}

resource "azurerm_kubernetes_cluster" "example" {
  name                = var.aks_cluster_name
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  dns_prefix          = "exampleaks"
  tags = {
    Environment = "example"
  }

  network_profile {
    network_plugin    = "azure"
    load_balancer_sku = "standard"
  }

  default_node_pool {
    name       = "default"
    node_count = 1
    vm_size    = "Standard_DS2_v2"
  }

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_kubernetes_cluster_node_pool" "example" {
  name                  = var.node_pool_name
  kubernetes_cluster_id = azurerm_kubernetes_cluster.example.id
  vm_size               = var.vm_size
  node_count            = var.node_count
  tags = {
    Environment = "example"
  }

  node_labels = {
    "nodepool" = var.node_pool_name
  }

  node_taints = [
    "nodepool=${var.node_pool_name}:NoSchedule"
  ]
}

output "resource_group_id" {
  value = azurerm_resource_group.example.id
}

output "virtual_network_id" {
  value = azurerm_virtual_network.example.id
}

output "subnet_id" {
  value = azurerm_subnet.example.id
}

output "aks_cluster_id" {
  value = azurerm_kubernetes_cluster.example.id
}

output "aks_cluster_node_pool_id" {
  value = azurerm_kubernetes_cluster_node_pool.example.id
}

output "aks_cluster_endpoint" {
  value = azurerm_kubernetes_cluster.example.kube_config[0].host
}