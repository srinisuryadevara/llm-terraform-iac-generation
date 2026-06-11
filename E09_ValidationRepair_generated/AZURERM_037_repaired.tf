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
  tags = {
    Environment = "example"
    ManagedBy   = "Terraform"
  }
}

resource "azurerm_storage_account" "example" {
  name                     = var.storage_account_name
  resource_group_name      = azurerm_resource_group.example.name
  location                 = azurerm_resource_group.example.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  tags = {
    Environment = "example"
    ManagedBy   = "Terraform"
  }
}

resource "azurerm_cdn_profile" "example" {
  name                = var.cdn_profile_name
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  sku                 = "Standard_Microsoft"
  tags = {
    Environment = "example"
    ManagedBy   = "Terraform"
  }
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
  tags = {
    Environment = "example"
    ManagedBy   = "Terraform"
  }
}

output "resource_group_id" {
  value       = azurerm_resource_group.example.id
  description = "ID of the resource group"
}

output "storage_account_id" {
  value       = azurerm_storage_account.example.id
  description = "ID of the storage account"
}

output "cdn_profile_id" {
  value       = azurerm_cdn_profile.example.id
  description = "ID of the CDN profile"
}

output "cdn_endpoint_id" {
  value       = azurerm_cdn_endpoint.example.id
  description = "ID of the CDN endpoint"
}

output "cdn_endpoint_hostname" {
  value       = azurerm_cdn_endpoint.example.host_name
  description = "Hostname of the CDN endpoint"
}