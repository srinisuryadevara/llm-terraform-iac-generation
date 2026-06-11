provider "azurerm" {
  features {}
}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "servicebus_namespace_name" {
  type = string
}

variable "servicebus_queue_name" {
  type = string
}

variable "servicebus_topic_name" {
  type = string
}

variable "servicebus_subscription_name" {
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
  name                = var.servicebus_namespace_name
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  sku                 = "Standard"
  tags = {
    environment = "example"
  }
}

resource "azurerm_servicebus_queue" "example" {
  name                = var.servicebus_queue_name
  namespace_name      = azurerm_servicebus_namespace.example.name
  resource_group_name = azurerm_resource_group.example.name
  tags = {
    environment = "example"
  }
}

resource "azurerm_servicebus_topic" "example" {
  name                = var.servicebus_topic_name
  namespace_name      = azurerm_servicebus_namespace.example.name
  resource_group_name = azurerm_resource_group.example.name
  tags = {
    environment = "example"
  }
}

resource "azurerm_servicebus_subscription" "example" {
  name                = var.servicebus_subscription_name
  namespace_name      = azurerm_servicebus_namespace.example.name
  topic_name          = azurerm_servicebus_topic.example.name
  resource_group_name = azurerm_resource_group.example.name
  tags = {
    environment = "example"
  }
}

output "resource_group_id" {
  value = azurerm_resource_group.example.id
}

output "servicebus_namespace_id" {
  value = azurerm_servicebus_namespace.example.id
}

output "servicebus_namespace_endpoint" {
  value = azurerm_servicebus_namespace.example.default_primary_connection_string
}

output "servicebus_queue_id" {
  value = azurerm_servicebus_queue.example.id
}

output "servicebus_topic_id" {
  value = azurerm_servicebus_topic.example.id
}

output "servicebus_subscription_id" {
  value = azurerm_servicebus_subscription.example.id
}