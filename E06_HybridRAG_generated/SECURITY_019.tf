terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.105.0"
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

  min_tls_version = "TLS1_2"

  blob_properties {
    cors_rule {
      allowed_headers = ["*"]
      allowed_methods = ["GET", "HEAD", "OPTIONS", "POST", "PUT"]
      allowed_origins = ["*"]
      exposed_headers  = ["*"]
      max_age_seconds  = 3600
    }
  }

  network_rules {
    default_action             = "Deny"
    ip_rules                   = []
    virtual_network_subnet_ids = []
    bypass                      = ["AzureServices"]
  }

  depends_on = [
    azurerm_resource_group.rg
  ]
}