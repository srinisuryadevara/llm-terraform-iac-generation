variable "name" {
  type        = string
  description = "Name of the Azure Key Vault"
}

variable "location" {
  type        = string
  description = "Location of the Azure Key Vault"
}

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group"
}

variable "tenant_id" {
  type        = string
  description = "Tenant ID of the Azure subscription"
}

variable "object_id" {
  type        = string
  description = "Object ID of the Azure AD application"
}

variable "sku_name" {
  type        = string
  description = "Sku name of the Azure Key Vault"
  default     = "standard"
}

variable "tags" {
  type        = map(string)
  description = "Tags for the Azure Key Vault"
  default     = {}
}

variable "enable_rbac_authorization" {
  type        = bool
  description = "Enable RBAC authorization for the Azure Key Vault"
  default     = true
}

variable "enable_soft_delete" {
  type        = bool
  description = "Enable soft delete for the Azure Key Vault"
  default     = true
}

variable "enable_purge_protection" {
  type        = bool
  description = "Enable purge protection for the Azure Key Vault"
  default     = true
}

data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "kv" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = var.sku_name
  soft_delete_enabled = var.enable_soft_delete
  purge_protection_enabled = var.enable_purge_protection

  tags = var.tags
}

resource "azurerm_key_vault_access_policy" "policy" {
  key_vault_id = azurerm_key_vault.kv.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = var.object_id

  key_permissions = [
    "Create",
    "Get",
    "List",
    "Update",
    "Delete",
    "Recover",
    "Backup",
    "Restore"
  ]

  secret_permissions = [
    "Get",
    "List",
    "Set",
    "Delete",
    "Recover",
    "Backup",
    "Restore"
  ]

  certificate_permissions = [
    "Get",
    "List",
    "Create",
    "Update",
    "Delete",
    "Recover",
    "Backup",
    "Restore"
  ]

  storage_permissions = [
    "Get",
    "List",
    "Create",
    "Update",
    "Delete",
    "Recover",
    "Backup",
    "Restore"
  ]
}

resource "azurerm_role_assignment" "assignment" {
  scope                = azurerm_key_vault.kv.id
  role_definition_name = "Key Vault Administrator"
  principal_id         = var.object_id
}