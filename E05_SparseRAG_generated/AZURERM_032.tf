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

# Deploy resource group
resource "azurerm_resource_group" "rg" {
  name     = var.rg_name
  location = var.default_location
}

# Deploy app service plan
resource "azurecaf_name" "plan_name" {
  name          = var.appservice_plan_id
  resource_type = "azurerm_app_service_plan"
  random_length = 0
  clean_input   = true
}

resource "azurerm_service_plan" "plan" {
  name                = azurecaf_name.plan_name.result
  location            = var.default_location
  resource_group_name = azurerm_resource_group.rg.name
  os_type             = "Linux"
  sku_name            = "B1"
}

# Deploy app service web app
resource "azurecaf_name" "web_name" {
  name          = "dio-webapp-${var.environment_name}"
  resource_type = "azurerm_app_service"
  random_length = 0
  clean_input   = true
}

resource "azurerm_linux_web_app" "web" {
  name                = azurecaf_name.web_name.result
  location            = var.default_location
  resource_group_name = azurerm_resource_group.rg.name
  service_plan_id     = azurerm_service_plan.plan.id

  site_config {
    application_stack {
      docker_image     = "mcr.microsoft.com/oss/nginx/nginx:1.15.5-alpine"
      docker_image_tag = "latest"
    }
  }

  app_settings = var.app_settings
}