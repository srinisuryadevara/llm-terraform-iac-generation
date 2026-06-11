provider "azurerm" {
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

variable "environment" {
  type        = string
  default     = "dev"
}

resource "azurerm_storage_account" "example" {
  name                     = var.storage_account_name
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"

  min_tls_version = "TLS1_2"

  blob_properties {
    default_access_level = "Private"
  }

  network_rules {
    default_action = "Deny"
    bypass         = ["AzureServices"]

    ip_rules = []

    virtual_network_rules = []
  }

  tags = {
    Environment = var.environment
  }
}

output "storage_account_id" {
  value       = azurerm_storage_account.example.id
  description = "The ID of the Storage Account"
}

output "storage_account_name" {
  value       = azurerm_storage_account.example.name
  description = "The name of the Storage Account"
}

output "storage_account_primary_blob_endpoint" {
  value       = azurerm_storage_account.example.primary_blob_endpoint
  description = "The primary blob endpoint of the Storage Account"
}