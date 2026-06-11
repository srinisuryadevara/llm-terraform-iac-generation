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
  description = "The location of the resource group"
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
  description = "The DNS prefix of the AKS cluster"
}

variable "service_cidr" {
  type        = string
  description = "The service CIDR of the AKS cluster"
}

variable "dns_service_ip" {
  type        = string
  description = "The DNS service IP of the AKS cluster"
}

variable "docker_bridge_cidr" {
  type        = string
  description = "The Docker bridge CIDR of the AKS cluster"
}

variable "pod_subnet_id" {
  type        = string
  description = "The ID of the pod subnet"
}

variable "vnet_subnet_id" {
  type        = string
  description = "The ID of the vnet subnet"
}

resource "azurerm_user_assigned_identity" "identity" {
  name                = "aks-identity"
  location            = var.location
  resource_group_name = var.resource_group_name
}

resource "azurerm_kubernetes_cluster" "k8" {
  name                    = var.cluster_id
  kubernetes_version      = var.kubernetes_version

  dns_prefix              = var.dns_prefix
  location                = var.location
  private_cluster_enabled = false
  resource_group_name     = var.resource_group_name

  network_profile {
    network_plugin     = "azure"
    service_cidr       = var.service_cidr
    dns_service_ip     = var.dns_service_ip
    docker_bridge_cidr = var.docker_bridge_cidr
  }

  default_node_pool {
    name            = "default"
    node_count      = var.node_count
    vm_size         = var.vm_size
    os_disk_size_gb = var.os_disk_size_gb
    pod_subnet_id   = var.pod_subnet_id
    vnet_subnet_id  = var.vnet_subnet_id
  }

  identity {
    type                      = "UserAssigned"
    user_assigned_identity_id = azurerm_user_assigned_identity.identity.id
  }
}