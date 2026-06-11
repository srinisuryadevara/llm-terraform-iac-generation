provider "azurerm" {
  version = "3.34.0"
  features {}
}

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group"
}

variable "resource_group_location" {
  type        = string
  description = "Location of the resource group"
}

variable "virtual_network_name" {
  type        = string
  description = "Name of the virtual network"
}

variable "virtual_network_address_space" {
  type        = list(string)
  description = "Address space of the virtual network"
}

variable "subnet_name" {
  type        = string
  description = "Name of the subnet"
}

variable "subnet_address_prefix" {
  type        = string
  description = "Address prefix of the subnet"
}

variable "network_security_group_name" {
  type        = string
  description = "Name of the network security group"
}

resource "azurerm_resource_group" "example" {
  name     = var.resource_group_name
  location = var.resource_group_location
  tags = {
    Environment = "example"
    ManagedBy   = "Terraform"
  }
}

resource "azurerm_virtual_network" "example" {
  name                = var.virtual_network_name
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  address_space       = var.virtual_network_address_space
  tags = {
    Environment = "example"
    ManagedBy   = "Terraform"
  }
}

resource "azurerm_subnet" "example" {
  name                 = var.subnet_name
  resource_group_name = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.example.name
  address_prefix       = var.subnet_address_prefix
  tags = {
    Environment = "example"
    ManagedBy   = "Terraform"
  }
}

resource "azurerm_network_security_group" "example" {
  name                = var.network_security_group_name
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  tags = {
    Environment = "example"
    ManagedBy   = "Terraform"
  }
}

resource "azurerm_subnet_network_security_group_association" "example" {
  subnet_id                 = azurerm_subnet.example.id
  network_security_group_id = azurerm_network_security_group.example.id
}

output "resource_group_id" {
  value       = azurerm_resource_group.example.id
  description = "ID of the resource group"
}

output "virtual_network_id" {
  value       = azurerm_virtual_network.example.id
  description = "ID of the virtual network"
}

output "subnet_id" {
  value       = azurerm_subnet.example.id
  description = "ID of the subnet"
}

output "network_security_group_id" {
  value       = azurerm_network_security_group.example.id
  description = "ID of the network security group"
}