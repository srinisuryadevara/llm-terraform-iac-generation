provider "azurerm" {
  version = "3.34.0"
  features {}
}

variable "location" {
  type        = string
  description = "Azure location"
}

variable "resource_group_name" {
  type        = string
  description = "Resource group name"
}

variable "registry_name" {
  type        = string
  description = "Container registry name"
}

variable "sku" {
  type        = string
  default     = "Premium"
  description = "Container registry SKU"
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Resource tags"
}

resource "azurerm_container_registry" "example" {
  name                     = var.registry_name
  resource_group_name      = var.resource_group_name
  location                 = var.location
  sku                      = var.sku
  admin_enabled            = false
  georeplication_locations = []
  tags                     = var.tags

  encryption {
    enabled = true
  }

  trust_policy {
    enabled = true
  }
}

output "registry_id" {
  value       = azurerm_container_registry.example.id
  description = "Container registry ID"
}

output "registry_login_server" {
  value       = azurerm_container_registry.example.login_server
  description = "Container registry login server"
}