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

variable "app_service_plan_name" {
  type = string
}

variable "app_service_plan_kind" {
  type = string
}

variable "app_service_plan_sku_tier" {
  type = string
}

variable "app_service_plan_sku_size" {
  type = string
}

variable "web_app_name" {
  type = string
}

variable "application_settings" {
  type = map(string)
}

resource "azurerm_resource_group" "example" {
  name     = var.resource_group_name
  location = var.location
  tags = {
    Environment = "example"
    ManagedBy   = "Terraform"
  }
}

resource "azurerm_app_service_plan" "example" {
  name                = var.app_service_plan_name
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  kind                = var.app_service_plan_kind
  sku {
    tier = var.app_service_plan_sku_tier
    size = var.app_service_plan_sku_size
  }
  tags = {
    Environment = "example"
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
    Environment = "example"
    ManagedBy   = "Terraform"
  }
}

output "resource_group_id" {
  value = azurerm_resource_group.example.id
}

output "app_service_plan_id" {
  value = azurerm_app_service_plan.example.id
}

output "app_service_id" {
  value = azurerm_app_service.example.id
}

output "app_service_endpoint" {
  value = azurerm_app_service.example.default_hostname
}