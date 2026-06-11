provider "azurerm" {
  features {}
}

variable "storage_account_name" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

resource "azurerm_storage_account" "example" {
  name                     = var.storage_account_name
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"
  min_tls_version         = "TLS1_2"
  enable_https_traffic_only = true

  blob_properties {
    versioning_enabled = false
    change_feed_enabled = false
    last_access_time_enabled = false
  }

  network_rules {
    default_action = "Deny"
    bypass = [
      "AzureServices",
    ]
  }
}