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

# Create the resource group
resource "azurerm_resource_group" "resource_group" {
  name     = var.resource_group_name
  location = var.azure_location
}

# Create the Azure Service Bus namespace
resource "azurerm_servicebus_namespace" "servicebus_namespace" {
  name                = var.servicebus_namespace_name
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name
  sku                 = "Standard"
}

# Create the Azure Service Bus queue
resource "azurerm_servicebus_queue" "servicebus_queue" {
  name                = var.servicebus_queue_name
  namespace_name      = azurerm_servicebus_namespace.servicebus_namespace.name
  resource_group_name = azurerm_resource_group.resource_group.name
}

# Create the Azure Service Bus topic
resource "azurerm_servicebus_topic" "servicebus_topic" {
  name                = var.servicebus_topic_name
  namespace_name      = azurerm_servicebus_namespace.servicebus_namespace.name
  resource_group_name = azurerm_resource_group.resource_group.name
}

# Create the Azure Service Bus topic subscription
resource "azurerm_servicebus_subscription" "servicebus_subscription" {
  name                = var.servicebus_subscription_name
  namespace_name      = azurerm_servicebus_namespace.servicebus_namespace.name
  topic_name          = azurerm_servicebus_topic.servicebus_topic.name
  resource_group_name = azurerm_resource_group.resource_group.name
}

variable "resource_group_name" {
  type        = string
  description = "The name of the resource group"
}

variable "azure_location" {
  type        = string
  description = "The location of the resource group"
}

variable "servicebus_namespace_name" {
  type        = string
  description = "The name of the Azure Service Bus namespace"
}

variable "servicebus_queue_name" {
  type        = string
  description = "The name of the Azure Service Bus queue"
}

variable "servicebus_topic_name" {
  type        = string
  description = "The name of the Azure Service Bus topic"
}

variable "servicebus_subscription_name" {
  type        = string
  description = "The name of the Azure Service Bus topic subscription"
}