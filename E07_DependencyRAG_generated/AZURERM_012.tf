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
  type        = string
  default     = "East Asia"
}

variable "resource_group_name" {
  type        = string
  default     = "terraform-resourcegroup"
}

variable "virtual_network_name" {
  type        = string
  default     = "example-vnet"
}

variable "subnet_name" {
  type        = string
  default     = "example-subnet"
}

variable "network_security_group_name" {
  type        = string
  default     = "example-nsg"
}

resource "azurerm_resource_group" "example" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_virtual_network" "example-vnet" {
  name                = var.virtual_network_name
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "example-subnet" {
  name                 = var.subnet_name
  virtual_network_name = azurerm_virtual_network.example-vnet.name
  resource_group_name  = azurerm_resource_group.example.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_network_security_group" "example-nsg" {
  name                = var.network_security_group_name
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
}

resource "azurerm_subnet_network_security_group_association" "example" {
  subnet_id                 = azurerm_subnet.example-subnet.id
  network_security_group_id = azurerm_network_security_group.example-nsg.id
}