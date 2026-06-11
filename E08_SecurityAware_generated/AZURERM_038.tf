provider "azurerm" {
  version = "3.34.0"
  features {}
}

variable "region" {
  type        = string
  description = "Azure region"
}

variable "project" {
  type        = string
  description = "Project name"
}

variable "environment" {
  type        = string
  description = "Environment name"
}

variable "storage_account_name" {
  type        = string
  description = "Storage account name"
}

variable "cdn_profile_name" {
  type        = string
  description = "CDN profile name"
}

variable "cdn_endpoint_name" {
  type        = string
  description = "CDN endpoint name"
}

variable "allowed_ips" {
  type        = list(string)
  description = "Allowed IP addresses for storage account"
}

resource "azurerm_resource_group" "example" {
  name     = "${var.project}-${var.environment}-rg"
  location = var.region
  tags = {
    environment = var.environment
    project     = var.project
  }
}

resource "azurerm_storage_account" "example" {
  name                     = var.storage_account_name
  resource_group_name      = azurerm_resource_group.example.name
  location                 = azurerm_resource_group.example.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"
  is_hns_enabled           = true
  min_tls_version          = "TLS1_2"
  network_rules {
    default_action = "Deny"
    ip_rules       = var.allowed_ips
  }
  tags = {
    environment = var.environment
    project     = var.project
  }
}

resource "azurerm_cdn_profile" "example" {
  name                = var.cdn_profile_name
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  sku                 = "Standard_Microsoft"
  tags = {
    environment = var.environment
    project     = var.project
  }
}

resource "azurerm_cdn_endpoint" "example" {
  name                = var.cdn_endpoint_name
  profile_name        = azurerm_cdn_profile.example.name
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  origin {
    name      = "example-origin"
    host_name = azurerm_storage_account.example.primary_blob_host
  }
  tags = {
    environment = var.environment
    project     = var.project
  }
}

resource "azurerm_storage_container" "example" {
  name                  = "example-container"
  storage_account_name  = azurerm_storage_account.example.name
  container_access_type = "private"
  tags = {
    environment = var.environment
    project     = var.project
  }
}