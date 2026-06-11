variable "azure_location" {
  type = string
}

variable "prefix" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "service_bus_namespace_name" {
  type = string
}

variable "queue_name" {
  type = string
}

variable "topic_name" {
  type = string
}

variable "subscription_name" {
  type = string
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

resource "azurerm_servicebus_subscription" "subscription" {
  name                = var.subscription_name
  resource_group_name = azurerm_resource_group.resource_group.name
  namespace_name      = azurerm_servicebus_namespace.service_bus_namespace.name
  topic_name          = azurerm_servicebus_topic.topic.name
  max_delivery_count  = 10
}