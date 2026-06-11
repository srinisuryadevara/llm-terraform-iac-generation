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
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

# Create the Azure Service Bus namespace
resource "azurerm_servicebus_namespace" "namespace" {
  name                = var.servicebus_namespace_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = var.servicebus_namespace_sku
}

# Create the Azure Service Bus queue
resource "azurerm_servicebus_queue" "queue" {
  name                = var.servicebus_queue_name
  namespace_name      = azurerm_servicebus_namespace.namespace.name
  resource_group_name = azurerm_resource_group.rg.name
}

# Create the Azure Service Bus topic
resource "azurerm_servicebus_topic" "topic" {
  name                = var.servicebus_topic_name
  namespace_name      = azurerm_servicebus_namespace.namespace.name
  resource_group_name = azurerm_resource_group.rg.name
}

# Create the Azure Service Bus topic subscription
resource "azurerm_servicebus_subscription" "subscription" {
  name                = var.servicebus_subscription_name
  namespace_name      = azurerm_servicebus_namespace.namespace.name
  topic_name          = azurerm_servicebus_topic.topic.name
  resource_group_name = azurerm_resource_group.rg.name
}

variable "resource_group_name" {
  type        = string
  description = "The name of the resource group"
}

variable "location" {
  type        = string
  description = "The location of the resource group"
}

variable "servicebus_namespace_name" {
  type        = string
  description = "The name of the Service Bus namespace"
}

variable "servicebus_namespace_sku" {
  type        = string
  description = "The SKU of the Service Bus namespace"
}

variable "servicebus_queue_name" {
  type        = string
  description = "The name of the Service Bus queue"
}

variable "servicebus_topic_name" {
  type        = string
  description = "The name of the Service Bus topic"
}

variable "servicebus_subscription_name" {
  type        = string
  description = "The name of the Service Bus topic subscription"
}