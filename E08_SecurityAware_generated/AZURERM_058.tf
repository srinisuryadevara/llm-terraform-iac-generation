provider "azurerm" {
  version = "3.34.0"
  features {}
}

variable "location" {
  type        = string
  description = "Azure location"
}

variable "resource_group_name" {
  type        = string
  description = "Resource group name"
}

variable "service_bus_namespace_name" {
  type        = string
  description = "Service Bus namespace name"
}

variable "service_bus_queue_name" {
  type        = string
  description = "Service Bus queue name"
}

variable "service_bus_topic_name" {
  type        = string
  description = "Service Bus topic name"
}

variable "tags" {
  type        = map(string)
  description = "Tags for resources"
}

resource "azurerm_resource_group" "example" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

resource "azurerm_servicebus_namespace" "example" {
  name                = var.service_bus_namespace_name
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  sku                 = "Standard"
  tags                = var.tags
}

resource "azurerm_servicebus_queue" "example" {
  name                = var.service_bus_queue_name
  namespace_name      = azurerm_servicebus_namespace.example.name
  resource_group_name = azurerm_resource_group.example.name
  enable_partitioning = true
  tags                = var.tags
}

resource "azurerm_servicebus_topic" "example" {
  name                = var.service_bus_topic_name
  namespace_name      = azurerm_servicebus_namespace.example.name
  resource_group_name = azurerm_resource_group.example.name
  enable_partitioning = true
  tags                = var.tags
}

resource "azurerm_servicebus_subscription" "example" {
  name                = "example-subscription"
  namespace_name      = azurerm_servicebus_namespace.example.name
  topic_name          = azurerm_servicebus_topic.example.name
  resource_group_name = azurerm_resource_group.example.name
  max_delivery_count  = 10
  tags                = var.tags
}