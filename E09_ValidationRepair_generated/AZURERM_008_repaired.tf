provider "azurerm" {
  features {}
}

variable "resource_group_name" {
  type        = string
  description = "The name of the resource group"
}

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

resource "azurerm_resource_group" "example" {
  name     = var.resource_group_name
  location = var.location
  tags = {
    Environment = "example"
    CreatedBy   = "Terraform"
  }
}

resource "azurerm_eventhub_namespace" "example" {
  name                = var.event_hub_namespace_name
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  sku                 = "Standard"
  capacity            = 1
  tags = {
    Environment = "example"
    CreatedBy   = "Terraform"
  }
}

resource "azurerm_eventhub" "example" {
  name                = var.event_hub_name
  namespace_name      = azurerm_eventhub_namespace.example.name
  resource_group_name = azurerm_resource_group.example.name
  partition_count     = 2
  message_retention   = 1
  tags = {
    Environment = "example"
    CreatedBy   = "Terraform"
  }
}

resource "azurerm_eventhub_consumer_group" "example" {
  name                = var.consumer_group_name
  namespace_name      = azurerm_eventhub_namespace.example.name
  eventhub_name       = azurerm_eventhub.example.name
  resource_group_name = azurerm_resource_group.example.name
  tags = {
    Environment = "example"
    CreatedBy   = "Terraform"
  }
}

output "resource_group_id" {
  value       = azurerm_resource_group.example.id
  description = "The ID of the resource group"
}

output "event_hub_namespace_id" {
  value       = azurerm_eventhub_namespace.example.id
  description = "The ID of the event hub namespace"
}

output "event_hub_id" {
  value       = azurerm_eventhub.example.id
  description = "The ID of the event hub"
}

output "event_hub_namespace_endpoint" {
  value       = azurerm_eventhub_namespace.example.endpoint
  description = "The endpoint of the event hub namespace"
}

output "event_hub_consumer_group_id" {
  value       = azurerm_eventhub_consumer_group.example.id
  description = "The ID of the event hub consumer group"
}