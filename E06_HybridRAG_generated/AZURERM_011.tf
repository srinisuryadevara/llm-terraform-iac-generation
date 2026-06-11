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

variable "resource_token" {
  type = string
}

variable "location" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "os_type" {
  type = string
}

variable "sku_name" {
  type = string
}

variable "tags" {
  type = map(string)
}

variable "basename" {
  type = string
}

variable "storage_account_tier" {
  type = string
}

variable "storage_account_replication_type" {
  type = string
}

variable "storage_account_kind" {
  type = string
}

variable "function_app_name" {
  type = string
}

variable "function_app_location" {
  type = string
}

variable "function_app_runtime" {
  type = object({
    os = string
    version = string
  })
}

variable "function_app_storage_account_name" {
  type = string
}

variable "function_app_storage_account_access_key" {
  type      = string
  sensitive = true
}

variable "function_app_site_config" {
  type = object({
    linux = object({
      enabled = bool
    })
    cors = object({
      allowed_origins = list(string)
    })
  })
}

variable "function_app_app_settings" {
  type = map(string)
}

data "azurerm_resource_group" "rg" {
  name = var.resource_group_name
}

resource "azurecaf_name" "storage_account_name" {
  name          = var.basename
  resource_type = "azurerm_storage_account"
  random_length = 0
  clean_input   = true
}

resource "azurerm_storage_account" "storage_account" {
  name                     = azurecaf_name.storage_account_name.result
  resource_group_name      = data.azurerm_resource_group.rg.name
  location                 = var.location
  account_tier             = var.storage_account_tier
  account_replication_type = var.storage_account_replication_type
  account_kind             = var.storage_account_kind

  tags = var.tags
}

resource "azurerm_storage_container" "container" {
  name                  = "function-app-container"
  storage_account_name  = azurerm_storage_account.storage_account.name
  container_access_type = "private"
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
  resource_group_name = data.azurerm_resource_group.rg.name
  os_type             = var.os_type
  sku_name            = var.sku_name

  tags = var.tags
}

resource "azurerm_function_app" "function_app" {
  name                       = var.function_app_name
  location                   = var.function_app_location
  resource_group_name        = data.azurerm_resource_group.rg.name
  app_service_plan_id        = azurerm_service_plan.plan.id
  storage_account_name       = azurerm_storage_account.storage_account.name
  storage_account_access_key = var.function_app_storage_account_access_key

  os_type = var.function_app_runtime.os

  site_config {
    linux = var.function_app_site_config.linux
    cors {
      allowed_origins = var.function_app_site_config.cors.allowed_origins
    }
  }

  app_settings = var.function_app_app_settings
}