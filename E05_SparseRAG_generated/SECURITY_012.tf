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
  default     = "standard"
  description = "SKU name of the Azure Key Vault"
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Tags for the Azure Key Vault"
}

variable "enable_rbac_authorization" {
  type        = bool
  default     = true
  description = "Enable RBAC authorization for the Azure Key Vault"
}

variable "enable_soft_delete" {
  type        = bool
  default     = true
  description = "Enable soft delete for the Azure Key Vault"
}

variable "enable_purge_protection" {
  type        = bool
  default     = true
  description = "Enable purge protection for the Azure Key Vault"
}

data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "kv" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = var.sku_name

  tags = var.tags

  enable_rbac_authorization = var.enable_rbac_authorization
  enable_soft_delete         = var.enable_soft_delete
  enable_purge_protection    = var.enable_purge_protection

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = var.object_id

    key_permissions = [
      "Create",
      "Get",
      "List",
      "Update",
      "Delete",
      "Recover",
      "Backup",
      "Restore",
    ]

    secret_permissions = [
      "Get",
      "List",
      "Set",
      "Delete",
      "Recover",
      "Purge",
    ]

    certificate_permissions = [
      "Get",
      "List",
      "Create",
      "Update",
      "Delete",
      "Recover",
      "Purge",
    ]

    storage_permissions = [
      "Get",
      "List",
      "Create",
      "Update",
      "Delete",
      "Recover",
      "Purge",
    ]
  }
}