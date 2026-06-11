terraform {
  required_version = "~> 1.9"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.47.0"
    }
    azurecaf = {
      source  = "aztfmod/azurecaf"
      version = "~> 1.2.24"
    }
  }
}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy    = true
      recover_soft_deleted_key_vaults = true
    }
  }
}

variable "location" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "resource_token" {
  type = string
}

variable "tags" {
  type = map(string)
}

variable "access_policy_object_ids" {
  type = list(string)
}

variable "principal_id" {
  type = string
}

variable "secrets" {
  type = map(string)
}

variable "sp_secret_permissions" {
  type = list(string)
}

resource "azurerm_resource_group" "tftest" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurecaf_name" "kv_name" {
  name          = var.resource_token
  resource_type = "azurerm_key_vault"
  random_length = 0
  clean_input   = true
}

resource "azurerm_key_vault" "kv" {
  name                     = azurecaf_name.kv_name.result
  location                 = azurerm_resource_group.tftest.location
  resource_group_name      = azurerm_resource_group.tftest.name
  tenant_id                = data.azurerm_client_config.current.tenant_id
  purge_protection_enabled = false
  sku_name                 = "standard"

  tags = var.tags
}

data "azurerm_client_config" "current" {}

resource "azurerm_key_vault_access_policy" "app" {
  count        = length(var.access_policy_object_ids)
  key_vault_id = azurerm_key_vault.kv.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = var.access_policy_object_ids[count.index]

  secret_permissions = [
    "Get",
    "Set",
    "List",
    "Delete",
  ]
}

resource "azurerm_key_vault_access_policy" "user" {
  count        = var.principal_id == "" ? 0 : 1
  key_vault_id = azurerm_key_vault.kv.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = var.principal_id

  secret_permissions = [
    "Get",
    "Set",
    "List",
    "Delete",
  ]
}

resource "azurerm_key_vault_access_policy" "sp" {
  key_vault_id = azurerm_key_vault.kv.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = data.azurerm_client_config.current.object_id

  secret_permissions = var.sp_secret_permissions
}

resource "azurerm_key_vault_secret" "keyvault_secrets" {
  depends_on   = [azurerm_key_vault_access_policy.app, azurerm_key_vault_access_policy.user, azurerm_key_vault_access_policy.sp]
  for_each     = var.secrets
  name         = each.key
  value        = each.value
  key_vault_id = azurerm_key_vault.kv.id
}

output "resource_group_name" {
  value = azurerm_resource_group.tftest.name
}

output "resource_group_location" {
  value = azurerm_resource_group.tftest.location
}

output "key_vault_name" {
  value = azurerm_key_vault.kv.name
}

output "key_vault_id" {
  value = azurerm_key_vault.kv.id
}