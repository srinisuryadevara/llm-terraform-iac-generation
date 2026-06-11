# Declare the required provider and its version
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.95.0"
    }
  }
}

# Configure the Azure provider
provider "azurerm" {
  features {}
}

# Define variables
variable "location" {
  type        = string
  description = "The location of the resource group"
}

variable "event_hub_namespace_name" {
  type        = string
  description = "The name of the event hub namespace"
}

variable "event_hub_name" {
  type        = string
  description = "The name of the event hub"
}

variable "consumer_group_name" {
  type        = string
  description = "The name of the consumer group"
}

# Create a resource group
resource "azurerm_resource_group" "this" {
  name     = "rg-event-hub"
  location = var.location
}

# Create an event hub namespace
resource "azurerm_eventhub_namespace" "this" {
  name                = var.event_hub_namespace_name
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  sku                 = "Standard"
  capacity            = 1
  kafka_enabled       = false
}

# Create an event hub
resource "azurerm_eventhub" "this" {
  name                = var.event_hub_name
  namespace_name      = azurerm_eventhub_namespace.this.name
  resource_group_name = azurerm_resource_group.this.name
  partition_count     = 2
  message_retention   = 1
}

# Create a consumer group
resource "azurerm_eventhub_consumer_group" "this" {
  name                = var.consumer_group_name
  namespace_name      = azurerm_eventhub_namespace.this.name
  eventhub_name       = azurerm_eventhub.this.name
  resource_group_name = azurerm_resource_group.this.name
}