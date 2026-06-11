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

variable "container_registry_name" {
  type        = string
  description = "The name of the container registry"
}

variable "sku" {
  type        = string
  default     = "Basic"
  description = "The SKU of the container registry"
}

resource "azurerm_resource_group" "example" {
  name     = var.resource_group_name
  location = var.location
  tags = {
    environment = "example"
    managed_by  = "Terraform"
  }
}

resource "azurerm_container_registry" "example" {
  name                     = var.container_registry_name
  resource_group_name      = azurerm_resource_group.example.name
  location                 = azurerm_resource_group.example.location
  sku                      = var.sku
  admin_enabled            = false
  tags = {
    environment = "example"
    managed_by  = "Terraform"
  }
}

output "resource_group_id" {
  value       = azurerm_resource_group.example.id
  description = "The ID of the resource group"
}

output "container_registry_id" {
  value       = azurerm_container_registry.example.id
  description = "The ID of the container registry"
}

output "container_registry_login_server" {
  value       = azurerm_container_registry.example.login_server
  description = "The login server of the container registry"
}