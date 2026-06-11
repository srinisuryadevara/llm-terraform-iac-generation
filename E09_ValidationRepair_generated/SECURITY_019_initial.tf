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
}