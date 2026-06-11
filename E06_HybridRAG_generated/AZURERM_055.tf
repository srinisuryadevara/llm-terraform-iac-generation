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

variable "function_app_runtime" {
  type = string
}

variable "function_app_version" {
  type = string
}

variable "consumption_plan_name" {
  type = string
}

variable "consumption_plan_sku" {
  type = string
}

# GET RESOURCE GROUP
data "azurerm_resource_group" "rg" {
  name = var.resource_group_name
}

# STORAGE ACCOUNT
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
  name                  = "functionapp"
  storage_account_name  = azurerm_storage_account.storage_account.name
  container_access_type = "private"
}

# CONSUMPTION PLAN
resource "azurecaf_name" "consumption_plan_name" {
  name          = var.consumption_plan_name
  resource_type = "azurerm_app_service_plan"
  random_length = 0
  clean_input   = true
}

resource "azurerm_service_plan" "consumption_plan" {
  name                = azurecaf_name.consumption_plan_name.result
  location            = var.location
  resource_group_name = data.azurerm_resource_group.rg.name
  os_type             = var.os_type
  sku_name            = var.consumption_plan_sku

  tags = var.tags
}

# FUNCTION APP
resource "azurecaf_name" "function_app_name" {
  name          = var.function_app_name
  resource_type = "azurerm_function_app"
  random_length = 0
  clean_input   = true
}

resource "azurerm_function_app" "function_app" {
  name                       = azurecaf_name.function_app_name.result
  location                   = var.location
  resource_group_name        = data.azurerm_resource_group.rg.name
  app_service_plan_id        = azurerm_service_plan.consumption_plan.id
  storage_account_name       = azurerm_storage_account.storage_account.name
  storage_account_access_key = azurerm_storage_account.storage_account.primary_access_key
  os_type                    = var.os_type
  version                    = var.function_app_version

  site_config {
    linux_fx_version = var.function_app_runtime
  }

  tags = var.tags
}