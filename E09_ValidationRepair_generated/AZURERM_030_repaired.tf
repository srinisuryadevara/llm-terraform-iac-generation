provider "azurerm" {
  features {}
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

resource "azurerm_resource_group" "example" {
  name     = var.resource_group_name
  location = var.location
  tags = {
    environment = "example"
    managedBy   = "Terraform"
  }
}

resource "azurerm_storage_account" "example" {
  name                     = var.storage_account_name
  resource_group_name      = azurerm_resource_group.example.name
  location                 = azurerm_resource_group.example.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  tags = {
    environment = "example"
    managedBy   = "Terraform"
  }
}

resource "azurerm_cdn_profile" "example" {
  name                = var.cdn_profile_name
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  sku                 = "Standard_Microsoft"
  tags = {
    environment = "example"
    managedBy   = "Terraform"
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
    environment = "example"
    managedBy   = "Terraform"
  }
}

output "resource_group_id" {
  value = azurerm_resource_group.example.id
}

output "storage_account_id" {
  value = azurerm_storage_account.example.id
}

output "cdn_profile_id" {
  value = azurerm_cdn_profile.example.id
}

output "cdn_endpoint_id" {
  value = azurerm_cdn_endpoint.example.id
}

output "cdn_endpoint_hostname" {
  value = azurerm_cdn_endpoint.example.host_name
}