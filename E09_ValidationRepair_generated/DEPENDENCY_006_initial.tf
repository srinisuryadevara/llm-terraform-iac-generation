provider "azurerm" {
  features {}
}

variable "resource_group_name" {
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

variable "private_link_service_name" {
  type = string
}

resource "azurerm_resource_group" "example" {
  name     = var.resource_group_name
  location = "West US"
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

resource "azurerm_private_link_service" "example" {
  name                = var.private_link_service_name
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  load_balancer_frontend_ip_configuration_ids = []
}

resource "azurerm_private_endpoint" "example" {
  name                = var.private_endpoint_name
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  subnet_id           = azurerm_subnet.example.id

  private_service_connection {
    name                           = "example-connection"
    private_connection_resource_id = azurerm_private_link_service.example.id
    subresource_names              = []
    is_manual_connection           = false
  }
}