#--------------------- PROVIDER ---------------------------------
terraform {
    required_providers {
        azurerm = {
            source = "hashicorp/azurerm"
            version = "=2.71.0"
        }
    }
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
  features {}
}

#--------------------- VARIABLE ---------------------------------
variable "location" {
  type = string
  default = "East Asia"
  description = "the default location of the resource"
}

variable "resource_group_name" {
  type = string
  description = "the name of the resource group"
}

variable "basename" {
  type = string
  description = "the name of the storage account"
}

variable "storage_account_kind" {
  type = string
  description = "Kind: BlobStorage, BlockBlobStorage, FileStorage, Storage and StorageV2"
  default = "StorageV2"
}

variable "storage_account_tier" {
  type = string
  description = "Standard and Premium. (BlockBlobStorage and FileStorage accounts only for Premium)"
  default = "Standard"
}

variable "storage_account_account_replication_type" {
  type = string
  description = "Type of replication: LRS, GRS, RA-GRS, ZRS"
  default = "LRS"
}

#--------------------- RESOURCE ---------------------------------
data "azurerm_resource_group" "rg" {
  name = var.resource_group_name
}

resource "azurerm_storage_account" "storage_account" {
  name                     = var.basename
  resource_group_name      = data.azurerm_resource_group.rg.name
  location                 = var.location
  account_tier             = var.storage_account_tier
  account_replication_type = var.storage_account_account_replication_type
  account_kind             = var.storage_account_kind

  tags = {
    "CostCenter" = "SpikeReply"
  }
}

resource "azurerm_storage_container" "containercrt" {
  name                  = "critical"
  storage_account_name  = azurerm_storage_account.storage_account.name
  container_access_type = "private"
}

resource "azurerm_storage_container" "containerpub" {
  name                  = "public"
  storage_account_name  = azurerm_storage_account.storage_account.name
  container_access_type = "private"
}