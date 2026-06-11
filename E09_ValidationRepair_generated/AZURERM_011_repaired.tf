provider "azurerm" {
  version = "3.34.0"
  features {}
}

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group"
}

variable "location" {
  type        = string
  description = "Location of the resources"
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

resource "azurerm_resource_group" "example" {
  name     = var.resource_group_name
  location = var.location
  tags = {
    Environment = "example"
    ManagedBy   = "Terraform"
  }
}

resource "azurerm_storage_account" "example" {
  name                     = var.storage_account_name
  resource_group_name      = azurerm_resource_group.example.name
  location                 = azurerm_resource_group.example.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  tags = {
    Environment = "example"
    ManagedBy   = "Terraform"
  }
}

resource "azurerm_service_plan" "example" {
  name                = var.consumption_plan_name
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  os_type             = "Linux"
  sku_name            = "Y1"
  tags = {
    Environment = "example"
    ManagedBy   = "Terraform"
  }
}

resource "azurerm_function_app" "example" {
  name                       = var.function_app_name
  resource_group_name        = azurerm_resource_group.example.name
  location                   = azurerm_resource_group.example.location
  storage_account_name       = azurerm_storage_account.example.name
  storage_account_access_key = azurerm_storage_account.example.primary_access_key
  service_plan_name          = azurerm_service_plan.example.name
  os_type                    = "linux"
  version                    = "~4"
  tags = {
    Environment = "example"
    ManagedBy   = "Terraform"
  }
}

output "resource_group_id" {
  value       = azurerm_resource_group.example.id
  description = "ID of the resource group"
}

output "storage_account_id" {
  value       = azurerm_storage_account.example.id
  description = "ID of the storage account"
}

output "function_app_id" {
  value       = azurerm_function_app.example.id
  description = "ID of the function app"
}

output "function_app_default_hostname" {
  value       = azurerm_function_app.example.default_hostname
  description = "Default hostname of the function app"
}