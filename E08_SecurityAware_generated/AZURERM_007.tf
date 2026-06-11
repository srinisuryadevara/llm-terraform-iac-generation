provider "azurerm" {
  version = "3.34.0"
  features {}
}

variable "project" {
  type        = string
  description = "Project name"
}

variable "environment" {
  type        = string
  description = "Environment name"
}

variable "location" {
  type        = string
  description = "Location"
}

variable "resource_group_name" {
  type        = string
  description = "Resource group name"
}

variable "key_vault_name" {
  type        = string
  description = "Key vault name"
}

variable "tenant_id" {
  type        = string
  description = "Tenant ID"
}

variable "object_id" {
  type        = string
  description = "Object ID"
}

variable "secret_name" {
  type        = string
  description = "Secret name"
}

variable "secret_value" {
  type        = string
  sensitive   = true
  description = "Secret value"
}

resource "azurerm_resource_group" "example" {
  name     = var.resource_group_name
  location = var.location
  tags = {
    project     = var.project
    environment = var.environment
  }
}

resource "azurerm_key_vault" "example" {
  name                        = var.key_vault_name
  location                    = azurerm_resource_group.example.location
  resource_group_name         = azurerm_resource_group.example.name
  tenant_id                   = var.tenant_id
  sku_name                    = "standard"
  soft_delete_retention_days  = 7
  purge_protection_enabled    = true
  enabled_for_disk_encryption = true
  tags = {
    project     = var.project
    environment = var.environment
  }
}

resource "azurerm_key_vault_access_policy" "example" {
  key_vault_id = azurerm_key_vault.example.id
  tenant_id    = var.tenant_id
  object_id    = var.object_id
  secret_permissions = [
    "get",
    "list",
    "set",
    "delete",
    "purge",
    "recover"
  ]
  certificate_permissions = [
    "get",
    "list",
    "create",
    "update",
    "delete"
  ]
  key_permissions = [
    "get",
    "list",
    "create",
    "update",
    "delete",
    "backup",
    "restore"
  ]
}

resource "azurerm_key_vault_secret" "example" {
  name         = var.secret_name
  value        = var.secret_value
  key_vault_id = azurerm_key_vault.example.id
  tags = {
    project     = var.project
    environment = var.environment
  }
}