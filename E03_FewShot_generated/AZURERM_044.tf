provider "azurerm" {
  version = "3.34.0"
  features {}
}

variable "storage_account_name" {
  type        = string
  sensitive   = true
}

variable "resource_group_name" {
  type        = string
  sensitive   = true
}

variable "location" {
  type        = string
  sensitive   = true
}

variable "account_tier" {
  type        = string
  default     = "Standard"
}

variable "account_replication_type" {
  type        = string
  default     = "LRS"
}

variable "account_kind" {
  type        = string
  default     = "StorageV2"
}

variable "blob_container_names" {
  type        = list(string)
  default     = ["container1", "container2"]
}

resource "azurerm_storage_account" "example" {
  name                     = var.storage_account_name
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = var.account_tier
  account_replication_type = var.account_replication_type
  account_kind             = var.account_kind

  min_tls_version = "TLS1_2"

  network_rules {
    default_action = "Deny"
    bypass         = ["AzureServices"]
  }
}

resource "azurerm_storage_container" "example" {
  count                 = length(var.blob_container_names)
  name                  = var.blob_container_names[count.index]
  storage_account_name  = azurerm_storage_account.example.name
  container_access_type = "private"
}