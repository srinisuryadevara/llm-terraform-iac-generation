variable "resource_group_name" {
  type        = string
  description = "Name of the resource group"
}

variable "location" {
  type        = string
  description = "Location of the resource group"
}

variable "cluster_id" {
  type        = string
  description = "ID of the AKS cluster"
}

variable "subnet_id" {
  type        = string
  description = "ID of the subnet"
}

variable "vnet_id" {
  type        = string
  description = "ID of the virtual network"
}

variable "node_count" {
  type        = number
  description = "Number of nodes in the node pool"
}

variable "vm_size" {
  type        = string
  description = "Size of the virtual machines"
}

variable "os_disk_size_gb" {
  type        = number
  description = "Size of the OS disk"
}

variable "kubernetes_version" {
  type        = string
  description = "Version of Kubernetes"
}

variable "dns_prefix" {
  type        = string
  description = "DNS prefix of the AKS cluster"
}

variable "service_cidr" {
  type        = string
  description = "Service CIDR of the AKS cluster"
}

variable "dns_service_ip" {
  type        = string
  description = "DNS service IP of the AKS cluster"
}

variable "docker_bridge_cidr" {
  type        = string
  description = "Docker bridge CIDR of the AKS cluster"
}

resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_virtual_network" "vnet" {
  name                = "aks-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "subnet" {
  name                 = "aks-subnet"
  resource_group_name = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
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
    service_cidr       = var.service_cidr
    dns_service_ip     = var.dns_service_ip
    docker_bridge_cidr = var.docker_bridge_cidr
  }

  default_node_pool {
    name            = "default"
    node_count      = var.node_count
    vm_size         = var.vm_size
    os_disk_size_gb = var.os_disk_size_gb
    vnet_subnet_id  = azurerm_subnet.subnet.id
  }

  identity {
    type                      = "UserAssigned"
    user_assigned_identity_id = azurerm_user_assigned_identity.identity.id
  }

  depends_on = [azurerm_subnet.subnet]
}