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

variable "key_vault_name" {
  type        = string
  description = "The name of the key vault"
}

variable "tenant_id" {
  type        = string
  description = "The tenant ID"
}

variable "object_id" {
  type        = string
  description = "The object ID"
}

resource "azurerm_resource_group" "example" {
  name     = var.resource_group_name
  location = var.location
  tags = {
    Environment = "example"
    ManagedBy   = "Terraform"
  }
}

resource "azurerm_key_vault" "example" {
  name                        = var.key_vault_name
  location                    = azurerm_resource_group.example.location
  resource_group_name         = azurerm_resource_group.example.name
  tenant_id                   = var.tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = true
  sku_name                    = "standard"
  tags = {
    Environment = "example"
    ManagedBy   = "Terraform"
  }
}

resource "azurerm_role_assignment" "example" {
  scope                = azurerm_key_vault.example.id
  role_definition_name = "Key Vault Administrator"
  principal_id         = var.object_id
}

output "resource_group_id" {
  value       = azurerm_resource_group.example.id
  description = "The ID of the resource group"
}

output "resource_group_name" {
  value       = azurerm_resource_group.example.name
  description = "The name of the resource group"
}

output "key_vault_id" {
  value       = azurerm_key_vault.example.id
  description = "The ID of the key vault"
}

output "key_vault_name" {
  value       = azurerm_key_vault.example.name
  description = "The name of the key vault"
}

output "key_vault_vault_uri" {
  value       = azurerm_key_vault.example.vault_uri
  description = "The URI of the key vault"
}