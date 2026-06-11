provider "azurerm" {
  version = "3.34.0"
  features {}
}

variable "location" {
  type        = string
  description = "Location for the Azure resources"
}

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group"
}

variable "registry_name" {
  type        = string
  description = "Name of the Azure Container Registry"
}

variable "sku" {
  type        = string
  description = "SKU for the Azure Container Registry"
  default     = "Premium"
}

variable "tags" {
  type        = map(string)
  description = "Tags for the Azure resources"
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

  depends_on = []
}

output "registry_id" {
  value       = azurerm_container_registry.example.id
  description = "ID of the Azure Container Registry"
}

output "registry_login_server" {
  value       = azurerm_container_registry.example.login_server
  description = "Login server for the Azure Container Registry"
}