provider "azurerm" {
  features {}
}

variable "azure_location" {
  type = string
}

variable "prefix" {
  type = string
}

variable "resource_group_name" {
  type = string
}

resource "azurerm_resource_group" "resource_group" {
  name     = var.resource_group_name
  location = var.azure_location
}

resource "azurerm_servicebus_namespace" "servicebus_namespace" {
  name                = "${var.prefix}servicebusnamespace"
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name
  sku                 = "Standard"
}

resource "azurerm_servicebus_queue" "servicebus_queue" {
  name                = "servicebusqueue"
  resource_group_name = azurerm_resource_group.resource_group.name
  namespace_name      = azurerm_servicebus_namespace.servicebus_namespace.name
  enable_partitioning = true
}

resource "azurerm_servicebus_topic" "servicebus_topic" {
  name                = "servicebustopic"
  resource_group_name = azurerm_resource_group.resource_group.name
  namespace_name      = azurerm_servicebus_namespace.servicebus_namespace.name
  enable_partitioning = true
}

resource "azurerm_servicebus_subscription" "servicebus_subscription" {
  name                = "servicebussubscription"
  resource_group_name = azurerm_resource_group.resource_group.name
  namespace_name      = azurerm_servicebus_namespace.servicebus_namespace.name
  topic_name          = azurerm_servicebus_topic.servicebus_topic.name
  max_delivery_count  = 10
}