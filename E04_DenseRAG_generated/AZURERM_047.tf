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

variable "resource_group_name" {
  type        = string
  description = "The name of the resource group"
}

variable "location_for_rg" {
  type        = string
  description = "The location of the resource group"
}

variable "storage_account_name" {
  type        = string
  description = "The name of the storage account"
}

variable "function_app_name" {
  type        = string
  description = "The name of the function app"
}

variable "consumption_plan_name" {
  type        = string
  description = "The name of the consumption plan"
}

variable "location_for_function_app" {
  type        = string
  description = "The location of the function app"
}

variable "os_type" {
  type        = string
  description = "The os type of the function app"
}

variable "sku_name" {
  type        = string
  description = "The sku name of the consumption plan"
}

variable "runtime" {
  type        = string
  description = "The runtime of the function app"
}

variable "version" {
  type        = string
  description = "The version of the function app runtime"
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
}

resource "azurecaf_name" "consumption_plan_name" {
  name          = var.consumption_plan_name
  resource_type = "azurerm_app_service_plan"
  random_length = 0
  clean_input   = true
}

resource "azurerm_service_plan" "consumption_plan" {
  name                = azurecaf_name.consumption_plan_name.result
  location            = var.location_for_function_app
  resource_group_name = azurerm_resource_group.rg.name
  os_type             = var.os_type
  sku_name            = var.sku_name
}

resource "azurecaf_name" "function_app_name" {
  name          = var.function_app_name
  resource_type = "azurerm_function_app"
  random_length = 0
  clean_input   = true
}

resource "azurerm_function_app" "function_app" {
  name                       = azurecaf_name.function_app_name.result
  location                   = var.location_for_function_app
  resource_group_name        = azurerm_resource_group.rg.name
  app_service_plan_id        = azurerm_service_plan.consumption_plan.id
  storage_account_name       = azurerm_storage_account.storage_account.name
  storage_account_access_key = azurerm_storage_account.storage_account.primary_access_key
  os_type                    = var.os_type
  version                    = var.version

  site_config {
    linux_fx_version = "${var.runtime}|${var.version}"
  }
}