provider "azurerm" {
  version = "3.34.0"
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

variable "app_service_plan_name" {
  type        = string
  description = "The name of the app service plan"
}

variable "app_service_plan_kind" {
  type        = string
  description = "The kind of the app service plan"
  default     = "Linux"
}

variable "app_service_plan_sku" {
  type        = string
  description = "The SKU of the app service plan"
  default     = "P1v2"
}

variable "web_app_name" {
  type        = string
  description = "The name of the web app"
}

variable "application_settings" {
  type        = map(string)
  description = "The application settings of the web app"
  default = {
    WEBSITE_NODE_DEFAULT_VERSION = "10.15.2"
    WEBSITE_RUN_FROM_PACKAGE     = "1"
  }
}

resource "azurerm_resource_group" "example" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_app_service_plan" "example" {
  name                = var.app_service_plan_name
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  kind                = var.app_service_plan_kind
  sku {
    tier = "Premium"
    size = var.app_service_plan_sku
  }
}

resource "azurerm_app_service" "example" {
  name                = var.web_app_name
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  app_service_plan_name = azurerm_app_service_plan.example.name

  dynamic "site_config" {
    for_each = var.app_service_plan_kind == "Linux" ? [1] : []
    content {
      linux_fx_version = "DOCKER|mcr.microsoft.com/azure-app-service/samples/node:12-lts"
    }
  }

  app_settings = var.application_settings
}