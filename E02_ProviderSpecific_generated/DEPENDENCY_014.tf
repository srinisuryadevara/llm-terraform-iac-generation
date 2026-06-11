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

variable "node_pool_vm_size" {
  type        = string
  default     = "Standard_DS2_v2"
}

variable "node_pool_node_count" {
  type        = number
  default     = 3
}

variable "kubernetes_version" {
  type        = string
  default     = "1.24.6"
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

  network_profile {
    network_plugin    = "azure"
    service_cidr      = "10.0.0.0/16"
    dns_service_ip   = "10.0.0.10"
    docker_bridge_cidr = "172.17.0.1/16"
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
  vm_size                = var.node_pool_vm_size
  node_count             = var.node_pool_node_count
  os_disk_size_gb        = 30

  node_labels = {
    "nodepool" = var.node_pool_name
  }

  node_taints = [
    "nodepool=${var.node_pool_name}:NoSchedule"
  ]

  upgrade_settings {
    max_surge             = "1"
  }

  vnet_subnet_id = azurerm_subnet.example.id
}