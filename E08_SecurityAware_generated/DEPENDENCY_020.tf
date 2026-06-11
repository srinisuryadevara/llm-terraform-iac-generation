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

variable "aks_node_count" {
  type        = number
  description = "Number of AKS nodes"
}

variable "aks_node_vm_size" {
  type        = string
  description = "AKS node VM size"
}

resource "azurerm_resource_group" "example" {
  name     = "${var.project}-${var.environment}-rg"
  location = var.region
  tags = {
    Environment = var.environment
    Project     = var.project
  }
}

resource "azurerm_virtual_network" "example" {
  name                = "${var.project}-${var.environment}-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  tags = {
    Environment = var.environment
    Project     = var.project
  }
}

resource "azurerm_subnet" "example" {
  name                 = "${var.project}-${var.environment}-subnet"
  resource_group_name = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.example.name
  address_prefixes     = ["10.0.1.0/24"]
  tags = {
    Environment = var.environment
    Project     = var.project
  }
}

resource "azurerm_kubernetes_cluster" "example" {
  name                = "${var.project}-${var.environment}-aks"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  dns_prefix          = "${var.project}-${var.environment}"
  kubernetes_version = "1.23.8"

  network_profile {
    network_plugin    = "azure"
    load_balancer_sku = "standard"
  }

  identity {
    type = "SystemAssigned"
  }

  tags = {
    Environment = var.environment
    Project     = var.project
  }
}

resource "azurerm_kubernetes_cluster_node_pool" "example" {
  name                  = "${var.project}-${var.environment}-nodepool"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.example.id
  vm_size               = var.aks_node_vm_size
  node_count            = var.aks_node_count
  os_disk_size_gb       = 30
  os_type               = "Linux"
  vnet_subnet_id        = azurerm_subnet.example.id

  node_labels = {
    Environment = var.environment
    Project     = var.project
  }

  tags = {
    Environment = var.environment
    Project     = var.project
  }
}

resource "azurerm_network_security_group" "example" {
  name                = "${var.project}-${var.environment}-nsg"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  tags = {
    Environment = var.environment
    Project     = var.project
  }
}

resource "azurerm_network_security_rule" "example" {
  name                        = "ssh-rule"
  resource_group_name         = azurerm_resource_group.example.name
  network_security_group_name = azurerm_network_security_group.example.name
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_address_prefix       = var.ssh_source_cidr
  source_port_range          = "*"
  destination_address_prefix  = azurerm_subnet.example.address_prefixes[0]
  destination_port_range      = "22"
}

resource "azurerm_subnet_network_security_group_association" "example" {
  subnet_id                 = azurerm_subnet.example.id
  network_security_group_id = azurerm_network_security_group.example.id
}