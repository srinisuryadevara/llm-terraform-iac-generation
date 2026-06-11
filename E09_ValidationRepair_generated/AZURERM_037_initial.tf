provider "azurerm" {
  version = "3.34.0"
  features {}
}

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group"
}

variable "storage_account_name" {
  type        = string
  description = "Name of the storage account"
}

variable "location" {
  type        = string
  description = "Location of the resources"
}

variable "cdn_profile_name" {
  type        = string
  description = "Name of the CDN profile"
}

variable "cdn_endpoint_name" {
  type        = string
  description = "Name of the CDN endpoint"
}

resource "azurerm_resource_group" "example" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_storage_account" "example" {
  name                     = var.storage_account_name
  resource_group_name      = azurerm_resource_group.example.name
  location                 = azurerm_resource_group.example.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_cdn_profile" "example" {
  name                = var.cdn_profile_name
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  sku                 = "Standard_Microsoft"
}

resource "azurerm_cdn_endpoint" "example" {
  name                = var.cdn_endpoint_name
  profile_name        = azurerm_cdn_profile.example.name
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location

  origin {
    name       = "example-origin"
    host_name  = azurerm_storage_account.example.primary_blob_host
    http_port  = 80
    https_port = 443
  }
}