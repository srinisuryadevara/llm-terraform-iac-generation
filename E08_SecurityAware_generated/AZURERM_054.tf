provider "azurerm" {
  version = "3.34.0"
  features {}
}

variable "region" {
  type        = string
  description = "Azure region"
}

variable "project" {
  type        = string
  description = "Project name"
}

variable "environment" {
  type        = string
  description = "Environment name"
}

variable "ssh_source_cidr" {
  type        = string
  description = "SSH source CIDR"
}

variable "aks_cluster_name" {
  type        = string
  description = "AKS cluster name"
}

variable "aks_resource_group_name" {
  type        = string
  description = "AKS resource group name"
}

variable "aks_node_pool_name" {
  type        = string
  description = "AKS node pool name"
}

variable "aks_node_count" {
  type        = number
  description = "AKS node count"
}

variable "aks_vm_size" {
  type        = string
  description = "AKS VM size"
}

resource "azurerm_resource_group" "aks" {
  name     = var.aks_resource_group_name
  location = var.region
  tags = {
    Environment = var.environment
    Project     = var.project
  }
}

resource "azurerm_kubernetes_cluster" "aks" {
  name                = var.aks_cluster_name
  location            = azurerm_resource_group.aks.location
  resource_group_name = azurerm_resource_group.aks.name
  dns_prefix          = var.aks_cluster_name
  kubernetes_version  = "1.23.8"

  default_node_pool {
    name       = var.aks_node_pool_name
    node_count = var.aks_node_count
    vm_size    = var.aks_vm_size
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin    = "azure"
    load_balancer_sku = "standard"
  }

  tags = {
    Environment = var.environment
    Project     = var.project
  }
}

resource "azurerm_network_security_group" "aks" {
  name                = "${var.aks_cluster_name}-nsg"
  location            = azurerm_resource_group.aks.location
  resource_group_name = azurerm_resource_group.aks.name

  security_rule {
    name                       = "SSH"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = var.ssh_source_cidr
    destination_address_prefix = "*"
  }

  tags = {
    Environment = var.environment
    Project     = var.project
  }
}

resource "azurerm_network_security_group_association" "aks" {
  network_security_group_id = azurerm_network_security_group.aks.id
  subnet_id                 = azurerm_subnet.aks.id
}

resource "azurerm_subnet" "aks" {
  name                 = "${var.aks_cluster_name}-subnet"
  resource_group_name = azurerm_resource_group.aks.name
  virtual_network_name = azurerm_virtual_network.aks.name
  address_prefixes     = ["10.1.0.0/16"]
}

resource "azurerm_virtual_network" "aks" {
  name                = "${var.aks_cluster_name}-vnet"
  location            = azurerm_resource_group.aks.location
  resource_group_name = azurerm_resource_group.aks.name
  address_space       = ["10.1.0.0/16"]

  tags = {
    Environment = var.environment
    Project     = var.project
  }
}