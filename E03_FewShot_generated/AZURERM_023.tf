provider "azurerm" {
  version = "3.34.0"
  features {}
}

variable "storage_account_name" {
  type        = string
  description = "The name of the storage account"
}

variable "resource_group_name" {
  type        = string
  description = "The name of the resource group"
}

variable "location" {
  type        = string
  description = "The location of the storage account"
}

variable "container_names" {
  type        = list(string)
  description = "The names of the blob containers"
}

resource "azurerm_storage_account" "example" {
  name                     = var.storage_account_name
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"
  is_hns_enabled           = true

  network_rules {
    default_action = "Deny"
    ip_rules       = []
    virtual_network_subnet_ids = []
  }
}

resource "azurerm_storage_container" "example" {
  count                 = length(var.container_names)
  name                  = var.container_names[count.index]
  storage_account_name  = azurerm_storage_account.example.name
  container_access_type = "private"
}