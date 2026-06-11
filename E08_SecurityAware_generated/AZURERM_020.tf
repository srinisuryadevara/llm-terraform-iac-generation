provider "azurerm" {
  version = "3.34.0"
  features {}
}

variable "location" {
  type        = string
  description = "The location of the Key Vault"
}

variable "resource_group_name" {
  type        = string
  description = "The name of the Resource Group"
}

variable "key_vault_name" {
  type        = string
  description = "The name of the Key Vault"
}

variable "tenant_id" {
  type        = string
  description = "The ID of the Azure Active Directory tenant"
}

variable "object_id" {
  type        = string
  description = "The ID of the Azure Active Directory object"
}

variable "secret_name" {
  type        = string
  description = "The name of the secret to store"
}

variable "secret_value" {
  type        = string
  sensitive   = true
  description = "The value of the secret to store"
}

resource "azurerm_resource_group" "example" {
  name     = var.resource_group_name
  location = var.location
  tags = {
    environment = "example"
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
    environment = "example"
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
    "purge",
    "recover"
  ]
}

resource "azurerm_key_vault_secret" "example" {
  name         = var.secret_name
  value        = var.secret_value
  key_vault_id = azurerm_key_vault.example.id
  expiration_date = "2025-12-30T20:00:00Z"
  tags = {
    environment = "example"
  }
}