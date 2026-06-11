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
  tags = {
    environment = "example"
  }
}

resource "azurerm_virtual_network" "example" {
  name                = var.virtual_network_name
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  tags = {
    environment = "example"
  }
}

resource "azurerm_subnet" "example" {
  name                 = var.subnet_name
  resource_group_name = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.example.name
  address_prefixes     = ["10.0.1.0/24"]
  tags = {
    environment = "example"
  }
}

resource "azurerm_private_link_service" "example" {
  name                = var.private_link_service_name
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  load_balancer_frontend_ip_configuration_ids = []
  tags = {
    environment = "example"
  }
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
  tags = {
    environment = "example"
  }
}

output "resource_group_id" {
  value = azurerm_resource_group.example.id
}

output "virtual_network_id" {
  value = azurerm_virtual_network.example.id
}

output "subnet_id" {
  value = azurerm_subnet.example.id
}

output "private_link_service_id" {
  value = azurerm_private_link_service.example.id
}

output "private_endpoint_id" {
  value = azurerm_private_endpoint.example.id
}