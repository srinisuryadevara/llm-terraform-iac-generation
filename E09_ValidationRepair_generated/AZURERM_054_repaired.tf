provider "azurerm" {
  version = "3.34.0"
  features {}
}

variable "subscription_id" {
  type        = string
  sensitive   = true
}

variable "client_id" {
  type        = string
  sensitive   = true
}

variable "client_secret" {
  type        = string
  sensitive   = true
}

variable "tenant_id" {
  type        = string
  sensitive   = true
}

variable "resource_group_name" {
  type        = string
}

variable "location" {
  type        = string
}

variable "cluster_name" {
  type        = string
}

variable "dns_prefix" {
  type        = string
}

variable "node_pool_name" {
  type        = string
}

variable "node_count" {
  type        = number
}

variable "vm_size" {
  type        = string
}

variable "kubernetes_version" {
  type        = string
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
  dns_prefix          = var.dns_prefix
  kubernetes_version  = var.kubernetes_version

  identity {
    type = "SystemAssigned"
  }

  default_node_pool {
    name       = var.node_pool_name
    node_count = var.node_count
    vm_size    = var.vm_size
  }

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

output "identity" {
  value = azurerm_kubernetes_cluster.example.identity[0]
}

output "node_resource_group" {
  value = azurerm_kubernetes_cluster.example.node_resource_group
}