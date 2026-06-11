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
  description = "The location of the Event Hub namespace"
}

variable "event_hub_namespace_name" {
  type        = string
  description = "The name of the Event Hub namespace"
}

variable "event_hub_name" {
  type        = string
  description = "The name of the Event Hub"
}

variable "consumer_group_name" {
  type        = string
  description = "The name of the Consumer Group"
}

# Create a resource group
resource "azurerm_resource_group" "this" {
  name     = "rg-${var.event_hub_namespace_name}"
  location = var.location
}

# Create an Event Hub namespace
resource "azurerm_eventhub_namespace" "this" {
  name                = var.event_hub_namespace_name
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  sku                 = "Standard"
  capacity            = 1
}

# Create an Event Hub
resource "azurerm_eventhub" "this" {
  name                = var.event_hub_name
  namespace_name      = azurerm_eventhub_namespace.this.name
  resource_group_name = azurerm_resource_group.this.name
  partition_count     = 2
  message_retention   = 1
}

# Create a Consumer Group
resource "azurerm_eventhub_consumer_group" "this" {
  name                = var.consumer_group_name
  namespace_name      = azurerm_eventhub_namespace.this.name
  eventhub_name       = azurerm_eventhub.this.name
  resource_group_name = azurerm_resource_group.this.name
}