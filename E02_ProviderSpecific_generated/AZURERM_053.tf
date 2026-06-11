provider "azurerm" {
  features {}
}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "bastion_host_name" {
  type = string
}

resource "azurerm_public_ip" "bastion_host_public_ip" {
  name                = "bastion-host-public-ip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_bastion_host" "bastion_host" {
  name                = var.bastion_host_name
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.bastion_host_subnet.id
    public_ip_address_id = azurerm_public_ip.bastion_host_public_ip.id
  }
}

resource "azurerm_virtual_network" "bastion_host_vnet" {
  name                = "bastion-host-vnet"
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "bastion_host_subnet" {
  name                 = "AzureBastionSubnet"
  resource_group_name = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.bastion_host_vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}