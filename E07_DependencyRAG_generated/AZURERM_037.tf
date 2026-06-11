terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.47.0"
    }
  }
}

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group"
}

variable "location" {
  type        = string
  description = "Location of the resources"
}

variable "storage_account_name" {
  type        = string
  description = "Name of the storage account"
}

variable "cdn_profile_name" {
  type        = string
  description = "Name of the CDN profile"
}

variable "cdn_endpoint_name" {
  type        = string
  description = "Name of the CDN endpoint"
}

variable "origin_host_header" {
  type        = string
  description = "Origin host header"
}

variable "origin_path" {
  type        = string
  description = "Origin path"
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
    name       = "storage-origin"
    host_name  = azurerm_storage_account.storage_account.name
    http_port  = 80
    https_port = 443
  }
  origin_host_header = azurerm_storage_account.storage_account.name
  origin_path        = var.origin_path
}