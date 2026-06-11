provider "azurerm" {
  version = "3.34.0"
  features {}
}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "storage_account_name" {
  type = string
}

variable "function_app_name" {
  type = string
}

variable "consumption_plan_name" {
  type = string
}

variable "storage_account_tier" {
  type = string
}

variable "storage_account_replication_type" {
  type = string
}

resource "azurerm_resource_group" "example" {
  name     = var.resource_group_name
  location = var.location
  tags = {
    environment = "example"
    managed_by  = "terraform"
  }
}

resource "azurerm_storage_account" "example" {
  name                     = var.storage_account_name
  resource_group_name      = azurerm_resource_group.example.name
  location                 = azurerm_resource_group.example.location
  account_tier             = var.storage_account_tier
  account_replication_type = var.storage_account_replication_type
  tags = {
    environment = "example"
    managed_by  = "terraform"
  }
}

resource "azurerm_consumption_plan" "example" {
  name                = var.consumption_plan_name
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  sku {
    tier = "Dynamic"
    size = "Y1"
  }
  tags = {
    environment = "example"
    managed_by  = "terraform"
  }
}

resource "azurerm_function_app" "example" {
  name                       = var.function_app_name
  resource_group_name        = azurerm_resource_group.example.name
  location                   = azurerm_resource_group.example.location
  account_storage_name       = azurerm_storage_account.example.name
  storage_account_access_key = azurerm_storage_account.example.primary_access_key
  os_type                    = "linux"
  version                    = "~4"
  plan {
    name     = azurerm_consumption_plan.example.name
    type     = "Consumption"
    publisher = "Microsoft"
    product   = "Serverless"
    core_quantity = 0
  }
  site_config {
    linux_fx_version = "DOCKER|mcr.microsoft.com/azure-app-service/samples/node:12-lts"
  }
  app_settings = {
    WEBSITE_NODE_DEFAULT_VERSION = "10.15.2"
  }
  tags = {
    environment = "example"
    managed_by  = "terraform"
  }
}

output "resource_group_id" {
  value = azurerm_resource_group.example.id
}

output "storage_account_id" {
  value = azurerm_storage_account.example.id
}

output "consumption_plan_id" {
  value = azurerm_consumption_plan.example.id
}

output "function_app_id" {
  value = azurerm_function_app.example.id
}

output "function_app_default_hostname" {
  value = azurerm_function_app.example.default_hostname
}