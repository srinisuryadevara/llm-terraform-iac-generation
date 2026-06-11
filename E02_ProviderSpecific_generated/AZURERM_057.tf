provider "azurerm" {
  features {}
}

variable "storage_account_name" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "container_names" {
  type = list(string)
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
  account_kind             = "StorageV2"
  is_hns_enabled           = "true"
  min_tls_version         = "TLS1_2"
  allow_blob_public_access = false
}

resource "azurerm_storage_container" "example" {
  count                 = length(var.container_names)
  name                   = var.container_names[count.index]
  storage_account_name   = azurerm_storage_account.example.name
  container_access_type = "private"
}

output "storage_account_id" {
  value = azurerm_storage_account.example.id
}

output "storage_account_name" {
  value = azurerm_storage_account.example.name
}

output "container_ids" {
  value = azurerm_storage_container.example.*.id
}