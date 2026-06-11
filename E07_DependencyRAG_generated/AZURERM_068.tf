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
  type        = string
  description = "The name of the resource group"
}

variable "environment" {
  type        = string
  description = "The environment of the resource group"
}

variable "location" {
  type        = string
  description = "The location of the resource group"
}

resource "azurerm_resource_group" "default" {
  name     = "${var.name}-${var.environment}-rg"
  location = var.location
}

resource "azurerm_eventhub_namespace" "example" {
  name                = "${var.name}-${var.environment}-ehns"
  location            = azurerm_resource_group.default.location
  resource_group_name = azurerm_resource_group.default.name
  sku                 = "Standard"
  capacity            = 1
  zone_redundant      = true
}

resource "azurerm_eventhub" "example" {
  name                = "${var.name}-${var.environment}-eh"
  namespace_name      = azurerm_eventhub_namespace.example.name
  resource_group_name = azurerm_resource_group.default.name
  partition_count     = 2
  message_retention   = 1
}

resource "azurerm_eventhub_consumer_group" "example" {
  name                = "${var.name}-${var.environment}-ehcg"
  namespace_name      = azurerm_eventhub_namespace.example.name
  eventhub_name       = azurerm_eventhub.example.name
  resource_group_name = azurerm_resource_group.default.name
}