provider "azurerm" {
  version = "3.34.0"
  features {}
}

variable "location" {
  type        = string
  description = "The location where the resources will be created"
}

variable "resource_group_name" {
  type        = string
  description = "The name of the resource group"
}

variable "acr_name" {
  type        = string
  description = "The name of the Azure Container Registry"
}

variable "sku" {
  type        = string
  description = "The SKU of the Azure Container Registry"
  default     = "Premium"
}

variable "tags" {
  type        = map(string)
  description = "The tags to be applied to the resources"
}

resource "azurerm_container_registry" "example" {
  name                     = var.acr_name
  resource_group_name      = var.resource_group_name
  location                 = var.location
  sku                      = var.sku
  admin_enabled            = false
  georeplication_locations = []
  tags                     = var.tags

  encryption {
    enabled = true
  }
}

output "acr_id" {
  value = azurerm_container_registry.example.id
}

output "acr_login_server" {
  value = azurerm_container_registry.example.login_server
}