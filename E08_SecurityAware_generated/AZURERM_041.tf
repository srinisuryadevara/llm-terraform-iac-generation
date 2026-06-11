provider "azurerm" {
  version = "3.34.0"
  features {}
}

variable "region" {
  type        = string
  description = "Azure region"
}

variable "project" {
  type        = string
  description = "Project name"
}

variable "environment" {
  type        = string
  description = "Environment name"
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

variable "subscription_name" {
  type        = string
  description = "Subscription name"
}

resource "azurerm_resource_group" "example" {
  name     = var.resource_group_name
  location = var.region
  tags = {
    environment = var.environment
    project     = var.project
  }
}

resource "azurerm_servicebus_namespace" "example" {
  name                = var.service_bus_namespace_name
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  sku                 = "Standard"
  capacity            = 1
  minimum_tls_version = "1.2"
  tags = {
    environment = var.environment
    project     = var.project
  }
}

resource "azurerm_servicebus_queue" "example" {
  name                = var.queue_name
  resource_group_name = azurerm_resource_group.example.name
  namespace_name      = azurerm_servicebus_namespace.example.name
  enable_partitioning = true
  tags = {
    environment = var.environment
    project     = var.project
  }
}

resource "azurerm_servicebus_topic" "example" {
  name                = var.topic_name
  resource_group_name = azurerm_resource_group.example.name
  namespace_name      = azurerm_servicebus_namespace.example.name
  enable_partitioning = true
  tags = {
    environment = var.environment
    project     = var.project
  }
}

resource "azurerm_servicebus_subscription" "example" {
  name                = var.subscription_name
  resource_group_name = azurerm_resource_group.example.name
  namespace_name      = azurerm_servicebus_namespace.example.name
  topic_name          = azurerm_servicebus_topic.example.name
  max_delivery_count  = 10
  tags = {
    environment = var.environment
    project     = var.project
  }
}