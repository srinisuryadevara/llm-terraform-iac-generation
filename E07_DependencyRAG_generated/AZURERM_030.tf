terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.47.0"
    }
  }
}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "storage_account_name" {
  type = string
}

variable "cdn_profile_name" {
  type = string
}

variable "cdn_endpoint_name" {
  type = string
}

resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_storage_account" "storage_account" {
  name                     = var.storage_account_name
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_cdn_profile" "cdn_profile" {
  name                = var.cdn_profile_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Standard_Microsoft"
}

resource "azurerm_cdn_endpoint" "cdn_endpoint" {
  name                = var.cdn_endpoint_name
  profile_name        = azurerm_cdn_profile.cdn_profile.name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  origin {
    name      = "storage-origin"
    host_name = azurerm_storage_account.storage_account.name
  }

  origin_host_header = azurerm_storage_account.storage_account.name

  delivery_rule {
    name  = "storage-rule"
    order = 1

    url_file_extension_condition {
      operator = "Any"
      match_values = [
        "*.jpg",
        "*.png",
        "*.gif",
      ]
    }

    url_rewrite_action {
      source_pattern = "/{urlPath}"
      destination     = "https://${azurerm_storage_account.storage_account.name}/{urlPath}"
      preserve_unmatched_path = false
    }
  }
}