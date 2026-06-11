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
  description = "Location of the resource group"
}

variable "app_service_plan_name" {
  type        = string
  description = "Name of the app service plan"
}

variable "app_service_plan_kind" {
  type        = string
  description = "Kind of the app service plan"
  default     = "Linux"
}

variable "app_service_plan_reserved" {
  type        = bool
  description = "Whether the app service plan is reserved"
  default     = true
}

variable "app_service_plan_sku_tier" {
  type        = string
  description = "Tier of the app service plan SKU"
  default     = "Standard"
}

variable "app_service_plan_sku_name" {
  type        = string
  description = "Name of the app service plan SKU"
  default     = "S1"
}

variable "web_app_name" {
  type        = string
  description = "Name of the web app"
}

variable "application_settings" {
  type        = map(string)
  description = "Application settings for the web app"
  default = {
    WEBSITE_NODE_DEFAULT_VERSION = "14-lts"
    WEBSITE_RUN_FROM_PACKAGE     = "1"
  }
}

resource "azurerm_resource_group" "example" {
  name     = var.resource_group_name
  location = var.location
  tags = {
    Environment = "Example"
    ManagedBy   = "Terraform"
  }
}

resource "azurerm_app_service_plan" "example" {
  name                = var.app_service_plan_name
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  kind                = var.app_service_plan_kind
  reserved            = var.app_service_plan_reserved

  sku {
    tier = var.app_service_plan_sku_tier
    size = var.app_service_plan_sku_name
  }
  tags = {
    Environment = "Example"
    ManagedBy   = "Terraform"
  }
}

resource "azurerm_app_service" "example" {
  name                = var.web_app_name
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  app_service_plan_name = azurerm_app_service_plan.example.name

  app_settings = var.application_settings
  tags = {
    Environment = "Example"
    ManagedBy   = "Terraform"
  }
}

output "resource_group_id" {
  value       = azurerm_resource_group.example.id
  description = "ID of the resource group"
}

output "app_service_plan_id" {
  value       = azurerm_app_service_plan.example.id
  description = "ID of the app service plan"
}

output "web_app_id" {
  value       = azurerm_app_service.example.id
  description = "ID of the web app"
}

output "web_app_default_hostname" {
  value       = azurerm_app_service.example.default_hostname
  description = "Default hostname of the web app"
}