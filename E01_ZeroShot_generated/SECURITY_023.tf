provider "azurerm" {
  features {}
}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "key_vault_name" {
  type = string
}

variable "tenant_id" {
  type = string
}

variable "object_id" {
  type = string
}

resource "azurerm_resource_group" "example" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_key_vault" "example" {
  name                        = var.key_vault_name
  location                    = azurerm_resource_group.example.location
  resource_group_name         = azurerm_resource_group.example.name
  tenant_id                   = var.tenant_id
  soft_delete_retention_days   = 7
  purge_protection_enabled     = true
  enabled_for_disk_encryption   = true
  enabled_for_template_deployment = true
  enabled_for_deployment       = true
  enabled_for_diagnostics      = true
  sku_name                     = "standard"
}

resource "azurerm_role_assignment" "example" {
  scope                = azurerm_key_vault.example.id
  role_definition_name  = "Key Vault Administrator"
  principal_id          = var.object_id
}