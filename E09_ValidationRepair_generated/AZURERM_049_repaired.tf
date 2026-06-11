provider "azurerm" {
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
  tags = {
    Environment = "example"
    ManagedBy   = "Terraform"
  }
}

resource "azurerm_kubernetes_cluster" "example" {
  name                = var.cluster_name
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  dns_prefix          = "exampleaks"
  tags = {
    Environment = "example"
    ManagedBy   = "Terraform"
  }

  identity {
    type = "SystemAssigned"
  }

  default_node_pool {
    name       = var.node_pool_name
    node_count = var.node_count
    vm_size    = var.vm_size
  }

  kubernetes_version = var.kubernetes_version

  network_profile {
    network_plugin    = "azure"
    load_balancer_sku = "standard"
  }

  depends_on = [
    azurerm_resource_group.example,
  ]
}

resource "azurerm_role_assignment" "example" {
  scope                = azurerm_kubernetes_cluster.example.id
  role_definition_name = "Azure Kubernetes Service Cluster Admin"
  principal_id         = azurerm_kubernetes_cluster.example.kubelet_identity[0].object_id
  tags = {
    Environment = "example"
    ManagedBy   = "Terraform"
  }
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