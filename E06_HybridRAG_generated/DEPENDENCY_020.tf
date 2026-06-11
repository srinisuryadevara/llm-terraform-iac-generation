# Configure the Azure Provider
provider "azurerm" {
  features {}
}

# Create a resource group
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

# Create a virtual network
resource "azurerm_virtual_network" "vnet" {
  name                = var.virtual_network_name
  address_space       = var.address_space
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

# Create a subnet
resource "azurerm_subnet" "subnet" {
  name                 = var.subnet_name
  resource_group_name = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = var.subnet_address_prefixes
}

# Create a user assigned identity (required for UserAssigned identity in combination with bringing our own subnet/nsg/etc)
resource "azurerm_user_assigned_identity" "identity" {
  name                = var.identity_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

# Create the AKS cluster.
resource "azurerm_kubernetes_cluster" "k8" {
  name                    = var.cluster_name
  kubernetes_version      = var.kubernetes_version

  dns_prefix              = var.dns_prefix
  location                = azurerm_resource_group.rg.location
  private_cluster_enabled = var.private_cluster_enabled
  resource_group_name     = azurerm_resource_group.rg.name

  network_profile {
    network_plugin     = var.network_plugin
    service_cidr       = var.service_cidr
    dns_service_ip     = var.dns_service_ip
    docker_bridge_cidr = var.docker_bridge_cidr
  }

  default_node_pool {
    name            = var.default_node_pool_name
    node_count      = var.default_node_pool_node_count
    vm_size         = var.default_node_pool_vm_size
    os_disk_size_gb = var.default_node_pool_os_disk_size_gb
    vnet_subnet_id  = azurerm_subnet.subnet.id
  }

  identity {
    type                      = "UserAssigned"
    user_assigned_identity_id = azurerm_user_assigned_identity.identity.id
  }

  depends_on = [azurerm_subnet.subnet]
}

variable "resource_group_name" {
  type        = string
  description = "The name of the resource group"
}

variable "location" {
  type        = string
  description = "The location of the resource group"
}

variable "virtual_network_name" {
  type        = string
  description = "The name of the virtual network"
}

variable "address_space" {
  type        = list(string)
  description = "The address space of the virtual network"
}

variable "subnet_name" {
  type        = string
  description = "The name of the subnet"
}

variable "subnet_address_prefixes" {
  type        = list(string)
  description = "The address prefixes of the subnet"
}

variable "identity_name" {
  type        = string
  description = "The name of the user assigned identity"
}

variable "cluster_name" {
  type        = string
  description = "The name of the AKS cluster"
}

variable "kubernetes_version" {
  type        = string
  description = "The version of Kubernetes"
}

variable "dns_prefix" {
  type        = string
  description = "The DNS prefix of the AKS cluster"
}

variable "private_cluster_enabled" {
  type        = bool
  description = "Whether the AKS cluster is private"
}

variable "network_plugin" {
  type        = string
  description = "The network plugin of the AKS cluster"
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

variable "default_node_pool_name" {
  type        = string
  description = "The name of the default node pool"
}

variable "default_node_pool_node_count" {
  type        = number
  description = "The number of nodes in the default node pool"
}

variable "default_node_pool_vm_size" {
  type        = string
  description = "The VM size of the default node pool"
}

variable "default_node_pool_os_disk_size_gb" {
  type        = number
  description = "The OS disk size of the default node pool"
}