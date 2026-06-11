terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=2.86.0"
    }
  }
}

variable "azure_location" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "bastion_host_name" {
  type = string
}

resource "azurerm_resource_group" "bastion_rg" {
  name     = var.resource_group_name
  location = var.azure_location
}

resource "azurerm_public_ip" "bastion_pip" {
  name                = "${var.bastion_host_name}-pip"
  location            = var.azure_location
  resource_group_name = azurerm_resource_group.bastion_rg.name
  allocation_method   = "Static"

  tags = {
    environment = "Bastion Terraform"
  }
}

resource "azurerm_bastion_host" "bastion_host" {
  name                = var.bastion_host_name
  location            = var.azure_location
  resource_group_name = azurerm_resource_group.bastion_rg.name

  ip_configuration {
    name                 = "bastion_ip_config"
    subnet_id            = azurerm_subnet.bastion_subnet.id
    public_ip_address_id = azurerm_public_ip.bastion_pip.id
  }

  tags = {
    environment = "Bastion Terraform"
  }
}

resource "azurerm_virtual_network" "bastion_vnet" {
  name                = "${var.bastion_host_name}-vnet"
  location            = var.azure_location
  resource_group_name = azurerm_resource_group.bastion_rg.name
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "bastion_subnet" {
  name                 = "${var.bastion_host_name}-subnet"
  resource_group_name = azurerm_resource_group.bastion_rg.name
  virtual_network_name = azurerm_virtual_network.bastion_vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}