terraform {
  required_providers {
    azurerm = {
      version = "~>3.47.0"
      source  = "hashicorp/azurerm"
    }
  }
}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "name" {
  type = string
}

variable "publisher_name" {
  type = string
}

variable "publisher_email" {
  type = string
}

variable "tags" {
  type = map(string)
}

variable "sku" {
  type = string
}

variable "skuCount" {
  type = number
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

variable "api_protocol" {
  type = string
}

data "azurerm_subscription" "current" {}

resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_api_management" "apim" {
  name                = var.name
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  publisher_name      = var.publisher_name
  publisher_email     = var.publisher_email
  tags                = var.tags
  sku_name            = "${var.sku}_${(var.sku == "Consumption") ? 0 : ((var.sku == "Developer") ? 1 : var.skuCount)}"
  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_api_management_product" "product" {
  product_id            = var.product_name
  api_management_name   = azurerm_api_management.apim.name
  resource_group_name   = azurerm_resource_group.rg.name
  display_name          = var.product_name
  subscription_required = false
  description           = var.product_description
}

resource "azurerm_api_management_api" "api" {
  name                = var.api_name
  resource_group_name = azurerm_resource_group.rg.name
  api_management_name = azurerm_api_management.apim.name
  revision            = var.api_revision
  path                = var.api_path
  protocols           = [var.api_protocol]
}

resource "azurerm_api_management_product_api" "product_api" {
  product_id            = azurerm_api_management_product.product.product_id
  api_management_name   = azurerm_api_management.apim.name
  resource_group_name   = azurerm_resource_group.rg.name
  api_id                = azurerm_api_management_api.api.id
}