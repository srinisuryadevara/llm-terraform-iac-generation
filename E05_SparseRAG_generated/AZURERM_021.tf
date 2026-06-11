variable "cluster_name" {
  type        = string
  description = "The name of the AKS cluster"
}

variable "location" {
  type        = string
  description = "The location of the AKS cluster"
}

variable "resource_group_name" {
  type        = string
  description = "The name of the resource group"
}

variable "dns_prefix" {
  type        = string
  description = "The DNS prefix of the AKS cluster"
}

variable "kubernetes_version" {
  type        = string
  description = "The version of Kubernetes"
}

variable "private_cluster_enabled" {
  type        = bool
  description = "Whether the cluster is private"
}

variable "agent_count" {
  type        = number
  description = "The number of agents in the default node pool"
}

variable "agent_vm_size" {
  type        = string
  description = "The size of the virtual machines in the default node pool"
}

variable "node_os_disk_size_gb" {
  type        = number
  description = "The size of the OS disk in GB"
}

variable "admin_group_id" {
  type        = string
  description = "The ID of the admin group"
}

variable "subnet_id" {
  type        = string
  description = "The ID of the subnet"
}

variable "vnet_subnet_id" {
  type        = string
  description = "The ID of the vnet subnet"
}

resource "azurerm_user_assigned_identity" "identity" {
  name                = "${var.cluster_name}-identity"
  location            = var.location
  resource_group_name = var.resource_group_name
}

resource "azurerm_kubernetes_cluster" "aks" {
  name                    = var.cluster_name
  location                = var.location
  resource_group_name     = var.resource_group_name
  dns_prefix              = var.dns_prefix
  kubernetes_version      = var.kubernetes_version
  private_cluster_enabled = var.private_cluster_enabled

  default_node_pool {
    name            = "default"
    node_count      = var.agent_count
    vm_size         = var.agent_vm_size
    os_disk_size_gb = var.node_os_disk_size_gb
    pod_subnet_id   = var.subnet_id
    vnet_subnet_id  = var.vnet_subnet_id
  }

  identity {
    type                      = "UserAssigned"
    user_assigned_identity_id = azurerm_user_assigned_identity.identity.id
  }

  network_profile {
    network_plugin     = "azure"
    service_cidr       = "10.0.0.0/16"
    dns_service_ip     = "10.0.0.10"
    docker_bridge_cidr = "172.17.0.1/16"
  }

  azure_active_directory_role_based_access_control {
    managed = true
    admin_group_object_ids = [var.admin_group_id]
  }
}