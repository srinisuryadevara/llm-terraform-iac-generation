provider "azurerm" {
  version = "3.34.0"
  features {}
}

variable "project_name" {
  type        = string
  description = "The name of the project"
}

variable "environment" {
  type        = string
  description = "The environment of the project"
}

variable "location" {
  type        = string
  description = "The location of the project"
}

variable "resource_group_name" {
  type        = string
  description = "The name of the resource group"
}

variable "key_vault_name" {
  type        = string
  description = "The name of the key vault"
}

variable "tenant_id" {
  type        = string
  description = "The tenant ID of the Azure Active Directory"
}

variable "object_id" {
  type        = string
  description = "The object ID of the Azure Active Directory"
}

resource "azurerm_resource_group" "example" {
  name     = var.resource_group_name
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
  enable_rbac_authorization  = true
  enable_purge_protection     = true
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
  name         = "example-secret"
  value        = "example-value"
  key_vault_id = azurerm_key_vault.example.id
  tags = {
    environment = var.environment
    project     = var.project_name
  }
}