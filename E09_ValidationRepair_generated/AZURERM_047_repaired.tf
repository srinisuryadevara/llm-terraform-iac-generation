provider "azurerm" {
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
  version                    = "4"
  tags = {
    Environment = "example"
    ManagedBy   = "Terraform"
  }
}

output "resource_group_id" {
  value = azurerm_resource_group.example.id
}

output "storage_account_id" {
  value = azurerm_storage_account.example.id
}

output "storage_account_name" {
  value = azurerm_storage_account.example.name
}

output "function_app_id" {
  value = azurerm_function_app.example.id
}

output "function_app_default_hostname" {
  value = azurerm_function_app.example.default_hostname
}

output "consumption_plan_id" {
  value = azurerm_service_plan.example.id
}