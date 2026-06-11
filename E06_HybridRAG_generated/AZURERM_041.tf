# Configure the Azure provider
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0.0"
    }
  }
  required_version = ">= 0.14.9"
}

provider "azurerm" {
  features {}
}

variable "azure_location" {
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

variable "service_bus_subscription_name" {
  type        = string
  description = "Service Bus subscription name"
}

# Create the resource group
resource "azurerm_resource_group" "resource_group" {
  name     = var.resource_group_name
  location = var.azure_location
}

# Create the Service Bus namespace
resource "azurerm_servicebus_namespace" "service_bus_namespace" {
  name                = var.service_bus_namespace_name
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name
  sku                 = "Standard"
}

# Create the Service Bus queue
resource "azurerm_servicebus_queue" "service_bus_queue" {
  name                = var.service_bus_queue_name
  namespace_name      = azurerm_servicebus_namespace.service_bus_namespace.name
  resource_group_name = azurerm_resource_group.resource_group.name
}

# Create the Service Bus topic
resource "azurerm_servicebus_topic" "service_bus_topic" {
  name                = var.service_bus_topic_name
  namespace_name      = azurerm_servicebus_namespace.service_bus_namespace.name
  resource_group_name = azurerm_resource_group.resource_group.name
}

# Create the Service Bus subscription
resource "azurerm_servicebus_subscription" "service_bus_subscription" {
  name                = var.service_bus_subscription_name
  namespace_name      = azurerm_servicebus_namespace.service_bus_namespace.name
  topic_name          = azurerm_servicebus_topic.service_bus_topic.name
  resource_group_name = azurerm_resource_group.resource_group.name
}