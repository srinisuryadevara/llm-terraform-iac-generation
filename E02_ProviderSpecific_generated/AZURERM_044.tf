provider "azurerm" {
  features {}
}

variable "storage_account_name" {
  type        = string
  sensitive   = true
}

variable "resource_group_name" {
  type        = string
  sensitive   = true
}

variable "location" {
  type        = string
  sensitive   = true
}

variable "account_tier" {
  type        = string
  default     = "Standard"
}

variable "account_replication_type" {
  type        = string
  default     = "LRS"
}

variable "account_kind" {
  type        = string
  default     = "StorageV2"
}

variable "access_tier" {
  type        = string
  default     = "Hot"
}

variable "container_names" {
  type        = list(string)
  default     = ["container1", "container2"]
}

resource "azurerm_resource_group" "example" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_storage_account" "example" {
  name                     = var.storage_account_name
  resource_group_name      = azurerm_resource_group.example.name
  location                 = azurerm_resource_group.example.location
  account_tier              = var.account_tier
  account_replication_type   = var.account_replication_type
  account_kind              = var.account_kind
  access_tier               = var.access_tier

  depends_on = [
    azurerm_resource_group.example
  ]
}

resource "azurerm_storage_container" "example" {
  count                 = length(var.container_names)
  name                   = var.container_names[count.index]
  storage_account_name   = azurerm_storage_account.example.name
  container_access_type  = "private"

  depends_on = [
    azurerm_storage_account.example
  ]
}