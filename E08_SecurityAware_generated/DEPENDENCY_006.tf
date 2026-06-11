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

variable "resource_group_name" {
  type        = string
  description = "Resource group name"
}

variable "virtual_network_name" {
  type        = string
  description = "Virtual network name"
}

variable "subnet_name" {
  type        = string
  description = "Subnet name"
}

variable "private_endpoint_name" {
  type        = string
  description = "Private endpoint name"
}

variable "private_connection_resource_id" {
  type        = string
  description = "Private connection resource ID"
}

variable "private_connection_resource_group_name" {
  type        = string
  description = "Private connection resource group name"
}

variable "private_connection_subresource_names" {
  type        = list(string)
  description = "Private connection subresource names"
}

variable "private_endpoint_tags" {
  type        = map(string)
  description = "Private endpoint tags"
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "example" {
  name     = var.resource_group_name
  location = var.region
  tags     = var.private_endpoint_tags
}

resource "azurerm_virtual_network" "example" {
  name                = var.virtual_network_name
  address_space       = ["10.0.0.0/16"]
  location            = var.region
  resource_group_name = azurerm_resource_group.example.name
  tags                = var.private_endpoint_tags
}

resource "azurerm_subnet" "example" {
  name                 = var.subnet_name
  resource_group_name = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.example.name
  address_prefixes     = ["10.0.1.0/24"]
  tags                 = var.private_endpoint_tags
}

resource "azurerm_private_endpoint" "example" {
  name                = var.private_endpoint_name
  location            = var.region
  resource_group_name = azurerm_resource_group.example.name
  subnet_id           = azurerm_subnet.example.id
  tags                = var.private_endpoint_tags

  private_service_connection {
    name                           = "example-connection"
    private_connection_resource_id = var.private_connection_resource_id
    subresource_names              = var.private_connection_subresource_names
    is_manual_connection           = false
  }
}