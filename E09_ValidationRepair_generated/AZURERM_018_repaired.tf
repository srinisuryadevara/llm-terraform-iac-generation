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

variable "service_bus_subscription_name" {
  type = string
}

resource "azurerm_resource_group" "example" {
  name     = var.resource_group_name
  location = var.location
  tags = {
    environment = "example"
  }
}

resource "azurerm_servicebus_namespace" "example" {
  name                = var.service_bus_namespace_name
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  sku                 = "Standard"
  tags = {
    environment = "example"
  }
}

resource "azurerm_servicebus_queue" "example" {
  name                = var.service_bus_queue_name
  resource_group_name = azurerm_resource_group.example.name
  namespace_name      = azurerm_servicebus_namespace.example.name
  enable_partitioning = true
  tags = {
    environment = "example"
  }
}

resource "azurerm_servicebus_topic" "example" {
  name                = var.service_bus_topic_name
  resource_group_name = azurerm_resource_group.example.name
  namespace_name      = azurerm_servicebus_namespace.example.name
  enable_partitioning = true
  tags = {
    environment = "example"
  }
}

resource "azurerm_servicebus_subscription" "example" {
  name                = var.service_bus_subscription_name
  resource_group_name = azurerm_resource_group.example.name
  namespace_name      = azurerm_servicebus_namespace.example.name
  topic_name          = azurerm_servicebus_topic.example.name
  max_delivery_count  = 10
  tags = {
    environment = "example"
  }
}

output "resource_group_id" {
  value = azurerm_resource_group.example.id
}

output "service_bus_namespace_id" {
  value = azurerm_servicebus_namespace.example.id
}

output "service_bus_namespace_endpoint" {
  value = azurerm_servicebus_namespace.example.default_primary_connection_string
}

output "service_bus_queue_id" {
  value = azurerm_servicebus_queue.example.id
}

output "service_bus_topic_id" {
  value = azurerm_servicebus_topic.example.id
}

output "service_bus_subscription_id" {
  value = azurerm_servicebus_subscription.example.id
}