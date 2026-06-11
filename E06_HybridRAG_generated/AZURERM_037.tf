terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.47.0"
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

variable "location_for_cdn" {
  type = string
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

resource "azurerm_cdn_profile" "cdn_profile" {
  name                = var.cdn_profile_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.location_for_cdn
  sku                 = "Standard_Microsoft"
}

resource "azurerm_cdn_endpoint" "cdn_endpoint" {
  name                = var.cdn_endpoint_name
  profile_name        = azurerm_cdn_profile.cdn_profile.name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  origin {
    name       = "storage-origin"
    host_name  = azurerm_storage_account.storage_account.primary_blob_host
    http_port  = 80
    https_port = 443
  }

  origin_group {
    name                = "storage-origin-group"
    health_probe_path   = "/"
    traffic_routing Disability = false
    origin {
      id   = azurerm_cdn_endpoint.cdn_endpoint.origin[0].id
      name = azurerm_cdn_endpoint.cdn_endpoint.origin[0].name
    }
  }
}