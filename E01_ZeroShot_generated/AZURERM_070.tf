provider "azurerm" {
  features {}
}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "api_management_name" {
  type = string
}

variable "publisher_name" {
  type = string
}

variable "publisher_email" {
  type = string
}

variable "sku_name" {
  type = string
}

variable "product_name" {
  type = string
}

variable "product_description" {
  type = string
}

variable "api_name" {
  type = string
}

variable "api_revision" {
  type = string
}

variable "api_path" {
  type = string
}

resource "azurerm_resource_group" "example" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_api_management" "example" {
  name                = var.api_management_name
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  publisher_name      = var.publisher_name
  publisher_email     = var.publisher_email
  sku_name            = var.sku_name
}

resource "azurerm_api_management_product" "example" {
  product_id            = var.product_name
  api_management_name  = azurerm_api_management.example.name
  resource_group_name   = azurerm_resource_group.example.name
  display_name          = var.product_name
  subscription_required = false
  description           = var.product_description
}

resource "azurerm_api_management_api" "example" {
  name                = var.api_name
  resource_group_name = azurerm_resource_group.example.name
  api_management_name = azurerm_api_management.example.name
  revision            = var.api_revision
  path                = var.api_path
  display_name        = var.api_name
}

resource "azurerm_api_management_product_api" "example" {
  product_id = azurerm_api_management_product.example.product_id
  api_name   = azurerm_api_management_api.example.name
  api_management_name = azurerm_api_management.example.name
  resource_group_name = azurerm_resource_group.example.name
}