provider "azurerm" {
  version = "3.34.0"
  features {}
}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "service_bus_namespace_name" {
  type = string
}

variable "service_bus_queue_name" {
  type = string
}

variable "service_bus_topic_name" {
  type = string
}

resource "azurerm_resource_group" "example" {
  name     = var.resource_group_name
  location = var.location
  tags = {
    Environment = "example"
    ManagedBy   = "Terraform"
  }
}

resource "azurerm_servicebus_namespace" "example" {
  name                = var.service_bus_namespace_name
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  sku                 = "Standard"
  tags = {
    Environment = "example"
    ManagedBy   = "Terraform"
  }
}

resource "azurerm_servicebus_queue" "example" {
  name                = var.service_bus_queue_name
  namespace_name      = azurerm_servicebus_namespace.example.name
  resource_group_name = azurerm_resource_group.example.name
  tags = {
    Environment = "example"
    ManagedBy   = "Terraform"
  }
}

resource "azurerm_servicebus_topic" "example" {
  name                = var.service_bus_topic_name
  namespace_name      = azurerm_servicebus_namespace.example.name
  resource_group_name = azurerm_resource_group.example.name
  tags = {
    Environment = "example"
    ManagedBy   = "Terraform"
  }
}

output "resource_group_id" {
  value = azurerm_resource_group.example.id
}

output "service_bus_namespace_id" {
  value = azurerm_servicebus_namespace.example.id
}

output "service_bus_namespace_endpoint" {
  value = azurerm_servicebus_namespace.example.endpoint
}

output "service_bus_queue_id" {
  value = azurerm_servicebus_queue.example.id
}

output "service_bus_topic_id" {
  value = azurerm_servicebus_topic.example.id
}