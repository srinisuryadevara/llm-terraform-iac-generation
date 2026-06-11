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
}

resource "azurerm_servicebus_namespace" "example" {
  name                = var.service_bus_namespace_name
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  sku                 = "Standard"
}

resource "azurerm_servicebus_queue" "example" {
  name                = var.service_bus_queue_name
  namespace_name      = azurerm_servicebus_namespace.example.name
  resource_group_name  = azurerm_resource_group.example.name
  enable_partitioning = true
}

resource "azurerm_servicebus_topic" "example" {
  name                = var.service_bus_topic_name
  namespace_name      = azurerm_servicebus_namespace.example.name
  resource_group_name  = azurerm_resource_group.example.name
  enable_partitioning = true
}