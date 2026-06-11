terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=2.86.0"
    }
  }
}

variable "azure_location" {
  type        = string
  description = "The location for the Azure Bastion Host"
}

variable "resource_group_name" {
  type        = string
  description = "The name of the resource group"
}

variable "bastion_host_name" {
  type        = string
  description = "The name of the Azure Bastion Host"
}

resource "azurerm_public_ip" "bastion_pip" {
  name                = "bastion-pip"
  location            = var.azure_location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = {
    environment = "Azure Bastion Host"
  }
}

resource "azurerm_bastion_host" "bastion_host" {
  name                = var.bastion_host_name
  location            = var.azure_location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                 = "bastion-ip-config"
    subnet_id            = var.subnet_id
    public_ip_address_id = azurerm_public_ip.bastion_pip.id
  }

  tags = {
    environment = "Azure Bastion Host"
  }
}

variable "subnet_id" {
  type        = string
  description = "The ID of the subnet for the Azure Bastion Host"
}