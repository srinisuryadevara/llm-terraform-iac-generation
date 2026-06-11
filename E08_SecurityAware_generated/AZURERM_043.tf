provider "azurerm" {
  version = "3.34.0"
  features {}
}

variable "project_name" {
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

variable "tenant_id" {
  type        = string
  description = "Tenant ID"
  sensitive   = true
}

variable "object_id" {
  type        = string
  description = "Object ID"
  sensitive   = true
}

variable "key_vault_name" {
  type        = string
  description = "Key Vault name"
}

variable "secret_name" {
  type        = string
  description = "Secret name"
}

variable "secret_value" {
  type        = string
  description = "Secret value"
  sensitive   = true
}

resource "azurerm_resource_group" "example" {
  name     = "${var.project_name}-${var.environment}-rg"
  location = var.location
  tags = {
    environment = var.environment
    project     = var.project_name
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
    environment = var.environment
    project     = var.project_name
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
  key_permissions = [
    "get",
    "list",
    "create",
    "update",
    "delete",
    "purge",
    "recover"
  ]
  certificate_permissions = [
    "get",
    "list",
    "create",
    "update",
    "delete",
    "purge",
    "recover"
  ]
}

resource "azurerm_key_vault_secret" "example" {
  name         = var.secret_name
  value        = var.secret_value
  key_vault_id = azurerm_key_vault.example.id
  tags = {
    environment = var.environment
    project     = var.project_name
  }
}