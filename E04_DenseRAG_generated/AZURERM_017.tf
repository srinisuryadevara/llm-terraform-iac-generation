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
  description = "The location of the Azure resources"
}

variable "resource_group_name" {
  type        = string
  description = "The name of the resource group"
}

variable "bastion_host_name" {
  type        = string
  description = "The name of the Azure Bastion Host"
}

resource "azurerm_resource_group" "example" {
  name     = var.resource_group_name
  location = var.azure_location
}

resource "azurerm_public_ip" "bastion_pip" {
  name                = "${var.bastion_host_name}-pip"
  location            = var.azure_location
  resource_group_name = azurerm_resource_group.example.name
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = {
    environment = "Azure Bastion Host"
  }
}

resource "azurerm_bastion_host" "example" {
  name                = var.bastion_host_name
  location            = var.azure_location
  resource_group_name = azurerm_resource_group.example.name

  ip_configuration {
    name                 = "example"
    subnet_id            = azurerm_subnet.example.id
    public_ip_address_id = azurerm_public_ip.bastion_pip.id
  }

  tags = {
    environment = "Azure Bastion Host"
  }
}

resource "azurerm_subnet" "example" {
  name                 = "AzureBastionSubnet"
  resource_group_name = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.example.name
  address_prefixes     = ["10.0.0.0/24"]
}

resource "azurerm_virtual_network" "example" {
  name                = "${var.bastion_host_name}-vnet"
  location            = var.azure_location
  resource_group_name = azurerm_resource_group.example.name
  address_space       = ["10.0.0.0/16"]
}