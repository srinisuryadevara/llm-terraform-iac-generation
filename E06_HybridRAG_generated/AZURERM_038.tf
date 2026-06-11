terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.47.0"
    }
    azurecaf = {
      source  = "aztfmod/azurecaf"
      version = "~>1.2.24"
    }
  }
}

provider "azurerm" {
  features {}
}

variable "resource_group_name" {
  type = string
}

variable "location_for_rg" {
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

variable "tags" {
  type = map(string)
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
}

resource "azurecaf_name" "cdn_profile_name" {
  name          = var.cdn_profile_name
  resource_type = "azurerm_cdn_profile"
  random_length = 0
  clean_input   = true
}

resource "azurerm_cdn_profile" "cdn_profile" {
  name                = azurecaf_name.cdn_profile_name.result
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "Standard_Microsoft"
  tags                = var.tags
}

resource "azurecaf_name" "cdn_endpoint_name" {
  name          = var.cdn_endpoint_name
  resource_type = "azurerm_cdn_endpoint"
  random_length = 0
  clean_input   = true
}

resource "azurerm_cdn_endpoint" "cdn_endpoint" {
  name                = azurecaf_name.cdn_endpoint_name.result
  profile_name        = azurerm_cdn_profile.cdn_profile.name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  origin {
    name       = "storage-origin"
    host_name  = azurerm_storage_account.storage_account.primary_blob_host
    http_port  = 80
    https_port = 443
  }
  origin_group {
    name = "storage-origin-group"
    origin_ids = [
      azurerm_cdn_endpoint.cdn_endpoint.origin[0].id
    ]
  }
  delivery_rule {
    name  = "storage-delivery-rule"
    order = 1
    url_file_extension_condition {
      operator = "Any"
      match_values = [
        ".jpg",
        ".png",
        ".gif",
        ".bmp",
        ".ico"
      ]
    }
    url_rewrite_action {
      source_pattern          = "/{urlPath}"
      destination             = "https://${azurerm_storage_account.storage_account.primary_blob_host}/{urlPath}"
      preserve_unmatched_path = false
    }
  }
}