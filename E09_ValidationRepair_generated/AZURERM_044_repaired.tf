provider "azurerm" {
  version = "3.0.2"
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

variable "container_names" {
  type        = list(string)
  sensitive   = true
}

resource "azurerm_resource_group" "example" {
  name     = var.resource_group_name
  location = var.location
  tags = {
    Environment = "example"
    ManagedBy   = "Terraform"
  }
}

resource "azurerm_storage_account" "example" {
  name                     = var.storage_account_name
  resource_group_name      = azurerm_resource_group.example.name
  location                 = azurerm_resource_group.example.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"
  is_hns_enabled           = true
  tags = {
    Environment = "example"
    ManagedBy   = "Terraform"
  }

  storage_data_lake_gen2_filesystem {
    name = "$web"
  }
}

resource "azurerm_storage_container" "example" {
  count                 = length(var.container_names)
  name                  = var.container_names[count.index]
  storage_account_name  = azurerm_storage_account.example.name
  container_access_type = "private"
  metadata = {
    Environment = "example"
    ManagedBy   = "Terraform"
  }
}

resource "azurerm_storage_account_network_rules" "example" {
  storage_account_id = azurerm_storage_account.example.id

  default_action             = "Deny"
  bypass                     = ["AzureServices"]
  ip_rules                   = []
  virtual_network_subnet_ids = []
  tags = {
    Environment = "example"
    ManagedBy   = "Terraform"
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

output "container_names" {
  value       = azurerm_storage_container.example.*.name
  description = "The names of the Storage Containers"
}