variable "cluster_id" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "kubernetes_version" {
  type = string
}

variable "dns_prefix" {
  type = string
}

variable "node_count" {
  type = number
}

variable "vm_size" {
  type = string
}

variable "os_disk_size_gb" {
  type = number
}

variable "service_cidr" {
  type = string
}

variable "dns_service_ip" {
  type = string
}

variable "docker_bridge_cidr" {
  type = string
}

variable "pod_subnet_id" {
  type = string
}

variable "vnet_subnet_id" {
  type = string
}

variable "identity_name" {
  type = string
}

resource "azurerm_user_assigned_identity" "identity" {
  name                = var.identity_name
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