provider "azurerm" {
  features {}
}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "virtual_network_name" {
  type = string
}

variable "subnet_name" {
  type = string
}

variable "private_endpoint_name" {
  type = string
}

variable "private_connection_resource_name" {
  type = string
}

variable "private_connection_resource_group_name" {
  type = string
}

variable "private_connection_resource_type" {
  type = string
}

variable "private_connection_resource_subresource_names" {
  type = list(string)
}

resource "azurerm_resource_group" "example" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_virtual_network" "example" {
  name                = var.virtual_network_name
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
}

resource "azurerm_subnet" "example" {
  name                 = var.subnet_name
  resource_group_name = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.example.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_private_endpoint" "example" {
  name                = var.private_endpoint_name
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  subnet_id           = azurerm_subnet.example.id

  private_service_connection {
    name                           = var.private_endpoint_name
    private_connection_resource_id = "/subscriptions/${data.azurerm_subscription.current.subscription_id}/resourceGroups/${var.private_connection_resource_group_name}/providers/${var.private_connection_resource_type}/${var.private_connection_resource_name}/${var.private_connection_resource_subresource_names[0]}"
    subresource_names              = var.private_connection_resource_subresource_names
  }
}

data "azurerm_subscription" "current" {
}