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

variable "rg_name" {
  type        = string
  description = "Resource Group Name"
}

variable "default_location" {
  type        = string
  description = "Default Location"
}

variable "appservice_plan_id" {
  type        = string
  description = "App Service Plan ID"
}

variable "environment_name" {
  type        = string
  description = "Environment Name"
}

variable "app_settings" {
  type        = map(string)
  description = "Application Settings"
}

# Create the resource group
resource "azurerm_resource_group" "rg" {
  name     = var.rg_name
  location = var.default_location
}

# Create the App Service Plan
resource "azurerm_service_plan" "plan" {
  name                = var.appservice_plan_id
  location            = var.default_location
  resource_group_name = azurerm_resource_group.rg.name
  os_type             = "Linux"
  sku_name            = "B1"
}

# Create the App Service Web App
resource "azurerm_linux_web_app" "web" {
  name                = "dio-webapp-${var.environment_name}"
  location            = var.default_location
  resource_group_name = azurerm_resource_group.rg.name
  service_plan_id     = azurerm_service_plan.plan.id

  site_config {
    application_stack {
      docker_image = "mcr.microsoft.com/oss/nginx/nginx:1.15.5-alpine"
    }
  }

  app_settings = var.app_settings
}

output "app_service_plan_id" {
  value = azurerm_service_plan.plan.id
}

output "web_app_name" {
  value = azurerm_linux_web_app.web.name
}