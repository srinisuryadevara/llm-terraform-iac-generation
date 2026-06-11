terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.105.0"
    }
  }
}

provider "azurerm" {
  features {}
}

variable "resource_group_name" {
  type        = string
  description = "The name of the resource group"
}

variable "location_for_rg" {
  type        = string
  description = "The location of the resource group"
}

variable "storage_account_name" {
  type        = string
  description = "The name of the storage account"
}

resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location_for_rg
}

resource "azurerm_storage_account" "storage_account" {
  name                     = var.storage_account_name
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  min_tls_version          = "TLS1_2"
  allow_blob_public_access = false
  default_to_oauth_auth    = true

  blob_properties {
    versioning_enabled = false
    change_feed_enabled = false
    last_access_time_enabled = false
  }
}

resource "azurerm_storage_account_network_rules" "example" {
  resource_group_name  = azurerm_resource_group.rg.name
  storage_account_name = azurerm_storage_account.storage_account.name

  default_action             = "Deny"
  bypass                     = ["AzureServices"]
  ip_rules                   = []
  virtual_network_subnet_ids = []

  depends_on = [
    azurerm_resource_group.rg,
    azurerm_storage_account.storage_account
  ]
}