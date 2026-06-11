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

resource "azurerm_storage_account" "example" {
  name                     = var.storage_account_name
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"

  min_tls_version = "TLS1_2"
  allow_https_traffic_only = true

  blob_properties {
    cors_rule {
      allowed_headers = ["*"]
      allowed_methods = ["GET", "POST", "PUT", "HEAD", "DELETE"]
      allowed_origins = ["*"]
      exposed_headers  = ["*"]
      max_age_seconds  = 200
    }
  }

  network_rules {
    default_action             = "Deny"
    bypass                     = ["AzureServices"]
    ip_rules                   = []
    virtual_network_subnet_ids = []
  }

  tags = {
    Environment = "example"
    ManagedBy   = "Terraform"
  }

  depends_on = []
}

resource "azurerm_storage_account_network_rules" "example" {
  resource_group_name  = var.resource_group_name
  storage_account_name = azurerm_storage_account.example.name

  default_action             = "Deny"
  bypass                     = ["AzureServices"]
  ip_rules                   = []
  virtual_network_subnet_ids = []

  depends_on = [azurerm_storage_account.example]
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

output "storage_account_primary_blob_host" {
  value       = azurerm_storage_account.example.primary_blob_host
  description = "The primary blob host of the Storage Account"
}