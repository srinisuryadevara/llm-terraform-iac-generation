terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.96.0"
    }
  }
}

provider "azurerm" {
  features {}
}

variable "name" {
  type = string
}

variable "environment" {
  type = string
}

variable "location" {
  type = string
}

variable "event_hub_namespace_name" {
  type = string
}

variable "event_hub_name" {
  type = string
}

variable "consumer_group_name" {
  type = string
}

resource "azurerm_resource_group" "default" {
  name     = "${var.name}-${var.environment}-rg"
  location = var.location
}

resource "azurerm_eventhub_namespace" "example" {
  name                = var.event_hub_namespace_name
  location            = azurerm_resource_group.default.location
  resource_group_name = azurerm_resource_group.default.name
  sku                 = "Standard"
  capacity            = 1
  tags = {
    environment = var.environment
  }
}

resource "azurerm_eventhub" "example" {
  name                = var.event_hub_name
  namespace_name      = azurerm_eventhub_namespace.example.name
  resource_group_name = azurerm_resource_group.default.name
  partition_count     = 2
  message_retention   = 1
}

resource "azurerm_eventhub_consumer_group" "example" {
  name                = var.consumer_group_name
  namespace_name      = azurerm_eventhub_namespace.example.name
  eventhub_name       = azurerm_eventhub.example.name
  resource_group_name = azurerm_resource_group.default.name
  user_metadata       = "some-metadata"
}