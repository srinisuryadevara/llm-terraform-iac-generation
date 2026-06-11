variable "azure_location" {
  type        = string
  description = "Azure location"
}

variable "prefix" {
  type        = string
  description = "Prefix for resource names"
}

variable "resource_group_name" {
  type        = string
  description = "Resource group name"
}

variable "service_bus_namespace_name" {
  type        = string
  description = "Service Bus namespace name"
}

variable "queue_name" {
  type        = string
  description = "Queue name"
}

variable "topic_name" {
  type        = string
  description = "Topic name"
}

resource "azurerm_resource_group" "resource_group" {
  name     = var.resource_group_name
  location = var.azure_location
}

resource "azurerm_servicebus_namespace" "service_bus_namespace" {
  name                = var.service_bus_namespace_name
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name
  sku                 = "Standard"
}

resource "azurerm_servicebus_queue" "queue" {
  name                = var.queue_name
  resource_group_name = azurerm_resource_group.resource_group.name
  namespace_name      = azurerm_servicebus_namespace.service_bus_namespace.name
  enable_partitioning = true
}

resource "azurerm_servicebus_topic" "topic" {
  name                = var.topic_name
  resource_group_name = azurerm_resource_group.resource_group.name
  namespace_name      = azurerm_servicebus_namespace.service_bus_namespace.name
  enable_partitioning = true
}