terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.47.0"
    }
    azurecaf = {
      source  = "aztfmod/azurecaf"
      version = "~>1.2.24"
    }
  }
}

provider "azurerm" {
  features {}
}

variable "location" {
  type = string
  default = "East Asia"
  description = "the default location of the resource"
}

variable "prefix-name" {
    type = string
    description = "The prefix that should attach to all resources"
}

variable "storage_account_kind" {
  type =string
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

variable "storage_account_access_tier" {
    type = string
    description = "Access Tier: Hot or Cool"
    default = "Hot"
}

variable "os_type" {
  type = string
  default = "Linux"
  description = "the os type of the app service plan"
}

variable "sku_name" {
  type = string
  default = "Y1"
  description = "the sku name of the app service plan"
}

variable "resource_group_name" {
  type = string
  description = "the name of the resource group"
}

variable "resource_token" {
  type = string
  description = "the token for the resource name"
}

variable "tags" {
  type = map(string)
  default = {}
  description = "the tags for the resources"
}

resource "azurerm_resource_group" "example" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_storage_account" "example" {
  name                     = "${var.prefix-name}-storageaccount"
  resource_group_name      = azurerm_resource_group.example.name
  location                 = azurerm_resource_group.example.location
  account_tier             = var.storage_account_tier
  account_replication_type = var.storage_account_account_replication_type
  account_kind             = var.storage_account_kind
  access_tier              = var.storage_account_access_tier
}

resource "azurecaf_name" "plan_name" {
  name          = var.resource_token
  resource_type = "azurerm_app_service_plan"
  random_length = 0
  clean_input   = true
}

resource "azurerm_service_plan" "plan" {
  name                = azurecaf_name.plan_name.result
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  os_type             = var.os_type
  sku_name            = var.sku_name

  tags = var.tags
}

resource "azurerm_function_app" "example" {
  name                       = "${var.prefix-name}-functionapp"
  location                   = azurerm_resource_group.example.location
  resource_group_name        = azurerm_resource_group.example.name
  app_service_plan_name      = azurerm_service_plan.plan.name
  app_service_plan_id        = azurerm_service_plan.plan.id
  storage_account_name       = azurerm_storage_account.example.name
  storage_account_access_key = azurerm_storage_account.example.primary_access_key
  os_type                    = var.os_type

  site_config {
    linux_fx_version = "DOCKER|mcr.microsoft.com/azure-app-service/samples/node:12-lts"
  }

  tags = var.tags
}