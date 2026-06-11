provider "azurerm" {
  version = "3.34.0"
  features {}
}

variable "resource_group_name" {
  type        = string
  description = "The name of the resource group"
}

variable "location" {
  type        = string
  description = "The location of the resource group"
}

variable "cluster_name" {
  type        = string
  description = "The name of the AKS cluster"
}

variable "node_pool_name" {
  type        = string
  description = "The name of the node pool"
}

variable "node_count" {
  type        = number
  description = "The number of nodes in the node pool"
}

variable "vm_size" {
  type        = string
  description = "The size of the virtual machines in the node pool"
}

variable "kubernetes_version" {
  type        = string
  description = "The version of Kubernetes to use"
}

variable "client_id" {
  type        = string
  sensitive   = true
  description = "The client ID of the managed identity"
}

variable "client_secret" {
  type        = string
  sensitive   = true
  description = "The client secret of the managed identity"
}

variable "tenant_id" {
  type        = string
  sensitive   = true
  description = "The tenant ID of the managed identity"
}

resource "azurerm_resource_group" "example" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_kubernetes_cluster" "example" {
  name                = var.cluster_name
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  dns_prefix          = "exampleaks"

  identity {
    type = "SystemAssigned"
  }

  default_node_pool {
    name       = var.node_pool_name
    node_count = var.node_count
    vm_size    = var.vm_size
  }

  network_profile {
    network_plugin    = "azure"
    load_balancer_sku = "standard"
  }

  depends_on = [
    azurerm_resource_group.example,
  ]
}

resource "azurerm_kubernetes_cluster_node_pool" "example" {
  name                  = var.node_pool_name
  kubernetes_cluster_id = azurerm_kubernetes_cluster.example.id
  node_count            = var.node_count
  vm_size               = var.vm_size
  mode                  = "System"

  depends_on = [
    azurerm_kubernetes_cluster.example,
  ]
}

output "client_certificate" {
  value     = azurerm_kubernetes_cluster.example.kube_config[0].client_certificate
  sensitive = true
}

output "client_key" {
  value     = azurerm_kubernetes_cluster.example.kube_config[0].client_key
  sensitive = true
}

output "cluster_ca_certificate" {
  value     = azurerm_kubernetes_cluster.example.kube_config[0].cluster_ca_certificate
  sensitive = true
}

output "host" {
  value = azurerm_kubernetes_cluster.example.kube_config[0].host
}