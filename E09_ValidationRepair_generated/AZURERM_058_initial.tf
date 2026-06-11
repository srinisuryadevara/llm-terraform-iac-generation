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
}

resource "azurerm_servicebus_namespace" "example" {
  name                = var.servicebus_namespace_name
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  sku                 = "Standard"
}

resource "azurerm_servicebus_queue" "example" {
  name                = var.servicebus_queue_name
  namespace_name      = azurerm_servicebus_namespace.example.name
  resource_group_name = azurerm_resource_group.example.name
}

resource "azurerm_servicebus_topic" "example" {
  name                = var.servicebus_topic_name
  namespace_name      = azurerm_servicebus_namespace.example.name
  resource_group_name = azurerm_resource_group.example.name
}

resource "azurerm_servicebus_subscription" "example" {
  name                = var.servicebus_subscription_name
  namespace_name      = azurerm_servicebus_namespace.example.name
  topic_name          = azurerm_servicebus_topic.example.name
  resource_group_name = azurerm_resource_group.example.name
}