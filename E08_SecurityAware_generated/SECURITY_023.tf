provider "azurerm" {
  version = "3.34.0"
  features {}
}

variable "location" {
  type        = string
  description = "The location for the resources"
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
  description = "The tenant ID for the Azure Active Directory"
}

variable "object_id" {
  type        = string
  description = "The object ID for the Azure Active Directory"
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
  soft_delete_retention_days  = 90
  purge_protection_enabled    = true
  sku_name                    = "standard"
  enabled_for_disk_encryption = true
  tags = {
    environment = "example"
  }
}

resource "azurerm_role_assignment" "example" {
  scope                = azurerm_key_vault.example.id
  role_definition_name = "Key Vault Administrator"
  principal_id         = var.object_id
}