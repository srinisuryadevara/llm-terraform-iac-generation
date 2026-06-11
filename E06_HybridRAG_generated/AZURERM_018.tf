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
resource "azurerm_resource_group" "example_rg" {
  name     = var.resource_group_name
  location = var.azure_location
}

# Create the Azure Service Bus namespace
resource "azurerm_servicebus_namespace" "example_namespace" {
  name                = var.servicebus_namespace_name
  location            = azurerm_resource_group.example_rg.location
  resource_group_name = azurerm_resource_group.example_rg.name
  sku                 = "Standard"
}

# Create the Azure Service Bus queue
resource "azurerm_servicebus_queue" "example_queue" {
  name                = var.servicebus_queue_name
  namespace_name      = azurerm_servicebus_namespace.example_namespace.name
  resource_group_name = azurerm_resource_group.example_rg.name

  enable_partitioning = true
}

# Create the Azure Service Bus topic
resource "azurerm_servicebus_topic" "example_topic" {
  name                = var.servicebus_topic_name
  namespace_name      = azurerm_servicebus_namespace.example_namespace.name
  resource_group_name = azurerm_resource_group.example_rg.name

  enable_partitioning = true
}

# Create the Azure Service Bus topic subscription
resource "azurerm_servicebus_subscription" "example_subscription" {
  name                = var.servicebus_subscription_name
  namespace_name      = azurerm_servicebus_namespace.example_namespace.name
  topic_name          = azurerm_servicebus_topic.example_topic.name
  resource_group_name = azurerm_resource_group.example_rg.name

  max_delivery_count = 10
}

variable "resource_group_name" {
  type        = string
  sensitive   = true
}

variable "azure_location" {
  type        = string
  sensitive   = true
}

variable "servicebus_namespace_name" {
  type        = string
  sensitive   = true
}

variable "servicebus_queue_name" {
  type        = string
  sensitive   = true
}

variable "servicebus_topic_name" {
  type        = string
  sensitive   = true
}

variable "servicebus_subscription_name" {
  type        = string
  sensitive   = true
}