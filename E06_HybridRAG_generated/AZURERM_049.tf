variable "cluster_id" {
  type        = string
  description = "The ID of the AKS cluster"
}

variable "resource_group_name" {
  type        = string
  description = "The name of the resource group"
}

variable "location" {
  type        = string
  description = "The location of the AKS cluster"
}

variable "node_count" {
  type        = number
  description = "The number of nodes in the default node pool"
}

variable "vm_size" {
  type        = string
  description = "The size of the virtual machines in the default node pool"
}

variable "os_disk_size_gb" {
  type        = number
  description = "The size of the OS disk in GB"
}

variable "kubernetes_version" {
  type        = string
  description = "The version of Kubernetes"
}

variable "dns_prefix" {
  type        = string
  description = "The DNS prefix for the AKS cluster"
}

variable "client_id" {
  type        = string
  sensitive   = true
  description = "The client ID of the service principal"
}

variable "client_secret" {
  type        = string
  sensitive   = true
  description = "The client secret of the service principal"
}

variable "tenant_id" {
  type        = string
  sensitive   = true
  description = "The tenant ID of the service principal"
}

variable "subscription_id" {
  type        = string
  sensitive   = true
  description = "The subscription ID of the service principal"
}

provider "azurerm" {
  client_id      = var.client_id
  client_secret = var.client_secret
  tenant_id      = var.tenant_id
  subscription_id = var.subscription_id
  features {}
}

resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_user_assigned_identity" "identity" {
  name                = "aks-identity"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_kubernetes_cluster" "k8" {
  name                    = var.cluster_id
  kubernetes_version      = var.kubernetes_version
  
  dns_prefix              = var.dns_prefix
  location                = azurerm_resource_group.rg.location
  private_cluster_enabled = false
  resource_group_name     = azurerm_resource_group.rg.name

  network_profile {
    network_plugin     = "azure"
    service_cidr       = "10.30.0.0/16"
    dns_service_ip     = "10.30.0.10"
    docker_bridge_cidr = "172.17.0.1/16"
  }

  default_node_pool {
    name            = "default"
    node_count      = var.node_count
    vm_size         = var.vm_size
    os_disk_size_gb = var.os_disk_size_gb
  }

  identity {
    type                      = "UserAssigned"
    user_assigned_identity_id = azurerm_user_assigned_identity.identity.id
  }
}