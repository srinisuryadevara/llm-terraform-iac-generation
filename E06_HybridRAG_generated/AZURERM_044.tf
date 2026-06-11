terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.105.0"
    }
  }
}

provider "azurerm" {
  features {}
}

variable "resource_group_name" {
  type        = string
  sensitive   = true
}

variable "location_for_rg" {
  type        = string
  sensitive   = true
}

variable "storage_account_name" {
  type        = string
  sensitive   = true
}

variable "container_names" {
  type        = list(string)
  default     = ["critical", "public", "private"]
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
  account_kind             = "StorageV2"

  tags = {
    "CostCenter" = "SpikeReply"
  }
}

resource "azurerm_storage_container" "containers" {
  for_each                 = toset(var.container_names)
  name                     = each.key
  storage_account_name     = azurerm_storage_account.storage_account.name
  container_access_type    = "private"
}