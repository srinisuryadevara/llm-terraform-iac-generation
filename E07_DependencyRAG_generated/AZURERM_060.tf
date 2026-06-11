terraform {
  required_providers {
    azurerm = {
      version = "~>3.47.0"
      source  = "hashicorp/azurerm"
    }
    azurecaf = {
      source  = "aztfmod/azurecaf"
      version = "~>1.2.24"
    }
  }
}

variable "resource_group_name" {
  type        = string
  description = "The name of the resource group"
}

variable "location" {
  type        = string
  description = "The location of the resources"
}

variable "service_plan_name" {
  type        = string
  description = "The name of the service plan"
}

variable "app_name" {
  type        = string
  description = "The name of the app"
}

variable "os_type" {
  type        = string
  description = "The type of the operating system"
}

variable "sku_name" {
  type        = string
  description = "The name of the SKU"
}

variable "app_settings" {
  type        = map(string)
  description = "The application settings"
}

variable "tags" {
  type        = map(string)
  description = "The tags for the resources"
}

resource "azurecaf_name" "service_plan_name" {
  name          = var.service_plan_name
  resource_type = "azurerm_app_service_plan"
  random_length = 0
  clean_input   = true
}

resource "azurerm_service_plan" "service_plan" {
  name                = azurecaf_name.service_plan_name.result
  location            = var.location
  resource_group_name = var.resource_group_name
  os_type             = var.os_type
  sku_name            = var.sku_name

  tags = var.tags
}

resource "azurecaf_name" "app_name" {
  name          = var.app_name
  resource_type = "azurerm_app_service"
  random_length = 0
  clean_input   = true
}

resource "azurerm_app_service" "app" {
  name                = azurecaf_name.app_name.result
  location            = var.location
  resource_group_name = var.resource_group_name
  app_service_plan_id = azurerm_service_plan.service_plan.id

  app_settings = var.app_settings

  tags = var.tags
}