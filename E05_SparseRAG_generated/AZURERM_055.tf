# Configure the Azure provider
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0.0"
    }
  }
  required_version = ">= 0.14.9"
}

provider "azurerm" {
  features {}
}

# Variables
variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "basename" {
  type = string
}

variable "function_app_name" {
  type = string
}

variable "storage_account_name" {
  type = string
}

variable "consumption_plan_name" {
  type = string
}

# Get resource group
data "azurerm_resource_group" "rg" {
  name = var.resource_group_name
}

# Create storage account
resource "azurerm_storage_account" "storage_account" {
  name                     = var.storage_account_name
  resource_group_name      = data.azurerm_resource_group.rg.name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"
}

# Create consumption plan
resource "azurerm_service_plan" "consumption_plan" {
  name                = var.consumption_plan_name
  location            = var.location
  resource_group_name = data.azurerm_resource_group.rg.name
  os_type             = "Linux"
  sku_name            = "Y1"
}

# Create function app
resource "azurerm_function_app" "function_app" {
  name                       = var.function_app_name
  location                   = var.location
  resource_group_name        = data.azurerm_resource_group.rg.name
  storage_account_name       = azurerm_storage_account.storage_account.name
  storage_account_access_key = azurerm_storage_account.storage_account.primary_access_key
  os_type                    = "linux"
  version                    = "~4"
  sku_name                   = "Y1"
  https_only                 = true
  site_config {
    linux_fx_version = "DOCKER|mcr.microsoft.com/azure-app-service/samples/node:12-lts"
  }
  app_settings = {
    WEBSITE_NODE_DEFAULT_VERSION = "10.15.2"
    FUNCTIONS_WORKER_RUNTIME     = "node"
  }
  depends_on = [azurerm_storage_account.storage_account, azurerm_service_plan.consumption_plan]
}