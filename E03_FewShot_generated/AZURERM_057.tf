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

variable "container_names" {
  type        = list(string)
  sensitive   = true
  default     = ["container1", "container2"]
}

resource "azurerm_storage_account" "example" {
  name                     = var.storage_account_name
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"
  is_hns_enabled           = true

  blob_properties {
    versioning {
      enabled = true
    }
    change_feed {
      enabled = true
    }
  }
}

resource "azurerm_storage_container" "example" {
  count                 = length(var.container_names)
  name                  = var.container_names[count.index]
  storage_account_name  = azurerm_storage_account.example.name
  container_access_type = "private"
}

resource "azurerm_storage_account_network_rules" "example" {
  storage_account_id = azurerm_storage_account.example.id

  default_action             = "Deny"
  bypass                     = ["AzureServices"]
  ip_rules                   = []
  virtual_network_subnet_ids = []
}