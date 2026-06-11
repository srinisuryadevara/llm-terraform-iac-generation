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

variable "resource_group_name" {
  type        = string
  description = "The name of the resource group"
}

variable "location" {
  type        = string
  description = "The location of the resource group"
}

variable "service_plan_name" {
  type        = string
  description = "The name of the service plan"
}

variable "web_app_name" {
  type        = string
  description = "The name of the web app"
}

variable "sku_name" {
  type        = string
  description = "The SKU name of the service plan"
}

variable "app_settings" {
  type        = map(string)
  description = "The application settings of the web app"
}

resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_service_plan" "appserviceplan" {
  name                = var.service_plan_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  os_type             = "Windows"
  sku_name            = var.sku_name
}

resource "azurerm_windows_web_app" "webapp" {
  name                  = var.web_app_name
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  service_plan_id       = azurerm_service_plan.appserviceplan.id
  https_only            = true
  site_config {
    minimum_tls_version = "1.2"
    application_stack {
      current_stack = "dotnet"
      dotnet_version = "v6.0"
    }
  }

  app_settings = var.app_settings
}

output "web_app_name" {
  value = azurerm_windows_web_app.webapp.name
}

output "web_app_id" {
  value = azurerm_windows_web_app.webapp.id
}