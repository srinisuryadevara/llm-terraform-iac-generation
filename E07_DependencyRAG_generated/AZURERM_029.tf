terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "=2.71.0"
    }
  }
}

provider "azurerm" {
  features {}
}

variable "location" {
  type = string
}

resource "azurerm_resource_group" "example" {
  name = "terraform-resourcegroup"
  location = var.location
}

resource "azurerm_virtual_network" "example-vnet" {
  name = "example-vnet"
  resource_group_name = azurerm_resource_group.example.name
  location = azurerm_resource_group.example.location
  address_space = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "example-subnet" {
  name = "example-subnet"
  virtual_network_name = azurerm_virtual_network.example-vnet.name
  resource_group_name = azurerm_resource_group.example.name
  address_prefixes = ["10.0.1.0/24"]
}

resource "azurerm_network_security_group" "example-nsg" {
  name = "example-nsg"
  resource_group_name = azurerm_resource_group.example.name
  location = azurerm_resource_group.example.location
}

resource "azurerm_subnet_network_security_group_association" "example-snsga" {
  subnet_id = azurerm_subnet.example-subnet.id
  network_security_group_id = azurerm_network_security_group.example-nsg.id
}