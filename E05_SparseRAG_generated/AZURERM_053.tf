# Configure the Azure provider
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0.0"
    }
  }
  required_version = ">= 0.14.9"
}

provider "azurerm" {
  features {}
}

# Create the resource group
resource "azurerm_resource_group" "rg" {
  name     = "${var.cluster_id}-gid"
  location = var.network_region
}

# Create the Azure Bastion Host
resource "azurerm_bastion_host" "bastion" {
  name                = "${var.cluster_id}-bastion"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Standard"
  scale_units         = 2

  ip_configuration {
    name                = "bastion-ip-config"
    subnet_id           = var.bastion_subnet_id
    public_ip_address_id = azurerm_public_ip.bastion.id
  }

  depends_on = [azurerm_resource_group.rg]
}

# Create the public IP for the Azure Bastion Host
resource "azurerm_public_ip" "bastion" {
  name                = "${var.cluster_id}-bastion-ip"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  allocation_method   = "Static"
  sku                 = "Standard"

  depends_on = [azurerm_resource_group.rg]
}

variable "cluster_id" {
  type = string
}

variable "network_region" {
  type = string
}

variable "bastion_subnet_id" {
  type = string
}