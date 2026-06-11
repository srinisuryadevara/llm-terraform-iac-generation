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
  description = "Name of the resource group"
}

variable "location_for_rg" {
  type        = string
  description = "Location of the resource group"
}

variable "storage_account_name" {
  type        = string
  description = "Name of the storage account"
}

variable "function_app_name" {
  type        = string
  description = "Name of the function app"
}

variable "consumption_plan_name" {
  type        = string
  description = "Name of the consumption plan"
}

variable "location_for_function_app" {
  type        = string
  description = "Location of the function app"
}

variable "os_type" {
  type        = string
  description = "OS type of the function app"
}

variable "sku_name" {
  type        = string
  description = "Sku name of the consumption plan"
}

variable "runtime" {
  type        = string
  description = "Runtime of the function app"
}

variable "version" {
  type        = string
  description = "Version of the function app runtime"
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

resource "azurerm_service_plan" "consumption_plan" {
  name                = var.consumption_plan_name
  location            = var.location_for_function_app
  resource_group_name = azurerm_resource_group.rg.name
  os_type             = var.os_type
  sku_name            = var.sku_name
}

resource "azurerm_function_app" "function_app" {
  name                       = var.function_app_name
  location                   = var.location_for_function_app
  resource_group_name        = azurerm_resource_group.rg.name
  storage_account_name       = azurerm_storage_account.storage_account.name
  storage_account_access_key = azurerm_storage_account.storage_account.primary_access_key
  service_plan_name          = azurerm_service_plan.consumption_plan.name
  os_type                    = var.os_type
  version                    = var.version

  site_config {
    linux_fx_version = "${var.runtime}|${var.version}"
  }
}