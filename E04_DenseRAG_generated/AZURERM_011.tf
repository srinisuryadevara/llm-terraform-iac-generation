terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.47.0"
    }
    azurecaf = {
      source  = "aztfmod/azurecaf"
      version = "~> 1.2.24"
    }
  }
}

provider "azurerm" {
  features {}
}

variable "resource_token" {
  type        = string
  description = "Resource token"
}

variable "location" {
  type        = string
  description = "Location"
}

variable "rg_name" {
  type        = string
  description = "Resource group name"
}

variable "storage_account_name" {
  type        = string
  description = "Storage account name"
}

variable "function_app_name" {
  type        = string
  description = "Function app name"
}

variable "os_type" {
  type        = string
  description = "OS type"
}

variable "sku_name" {
  type        = string
  description = "SKU name"
}

variable "tags" {
  type        = map(string)
  description = "Tags"
}

resource "azurecaf_name" "storage_account_name" {
  name          = var.storage_account_name
  resource_type = "azurerm_storage_account"
  random_length = 0
  clean_input   = true
}

resource "azurerm_storage_account" "storage_account" {
  name                     = azurecaf_name.storage_account_name.result
  resource_group_name      = var.rg_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurecaf_name" "plan_name" {
  name          = var.resource_token
  resource_type = "azurerm_app_service_plan"
  random_length = 0
  clean_input   = true
}

resource "azurerm_service_plan" "plan" {
  name                = azurecaf_name.plan_name.result
  location            = var.location
  resource_group_name = var.rg_name
  os_type             = var.os_type
  sku_name            = var.sku_name

  tags = var.tags
}

resource "azurecaf_name" "function_app_name" {
  name          = var.function_app_name
  resource_type = "azurerm_function_app"
  random_length = 0
  clean_input   = true
}

resource "azurerm_function_app" "function_app" {
  name                       = azurecaf_name.function_app_name.result
  location                   = var.location
  resource_group_name        = var.rg_name
  app_service_plan_id        = azurerm_service_plan.plan.id
  storage_account_name       = azurerm_storage_account.storage_account.name
  storage_account_access_key = azurerm_storage_account.storage_account.primary_access_key
  os_type                    = var.os_type
  version                    = "~4"

  site_config {
    linux_fx_version = "DOCKER|mcr.microsoft.com/azure-app-service/samples/node:12-lts"
  }

  tags = var.tags
}