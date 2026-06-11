provider "azurerm" {
  features {}
}

variable "location" {
  type        = string
  default     = "West US"
}

variable "resource_group_name" {
  type        = string
  default     = "example-resource-group"
}

variable "virtual_network_name" {
  type        = string
  default     = "example-virtual-network"
}

variable "subnet_name" {
  type        = string
  default     = "example-subnet"
}

variable "aks_cluster_name" {
  type        = string
  default     = "example-aks-cluster"
}

variable "node_pool_name" {
  type        = string
  default     = "example-node-pool"
}

variable "kubernetes_version" {
  type        = string
  default     = "1.24.3"
}

variable "vm_size" {
  type        = string
  default     = "Standard_DS2_v2"
}

variable "node_count" {
  type        = number
  default     = 3
}

resource "azurerm_resource_group" "example" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_virtual_network" "example" {
  name                = var.virtual_network_name
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
}

resource "azurerm_subnet" "example" {
  name                 = var.subnet_name
  resource_group_name = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.example.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_kubernetes_cluster" "example" {
  name                = var.aks_cluster_name
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  dns_prefix          = "exampleaks"

  kubernetes_version = var.kubernetes_version

  network_profile {
    network_plugin    = "azure"
    load_balancer_sku = "standard"
  }

  default_node_pool {
    name       = "default"
    node_count = var.node_count
    vm_size    = var.vm_size
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

  vnet_subnet_id = azurerm_subnet.example.id
}