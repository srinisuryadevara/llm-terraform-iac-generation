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

variable "name" {
  type = string
}

variable "location" {
  type = string
}

variable "resource_group_name" {
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

variable "api_name" {
  type = string
}

variable "api_display_name" {
  type = string
}

variable "api_path" {
  type = string
}

variable "api_backend_url" {
  type = string
}

variable "product_name" {
  type = string
}

variable "product_display_name" {
  type = string
}

variable "product_description" {
  type = string
}

variable "product_terms" {
  type = string
}

variable "product_approval_required" {
  type = bool
}

variable "product_subscriptions_limit" {
  type = number
}

variable "product_state" {
  type = string
}

resource "azurerm_api_management" "apim" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  publisher_name      = var.publisher_name
  publisher_email     = var.publisher_email
  tags                = var.tags
  sku_name            = "${var.sku}_${(var.sku == "Consumption") ? 0 : ((var.sku == "Developer") ? 1 : var.skuCount)}"
  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_api_management_api" "api" {
  name                = var.api_name
  resource_group_name = var.resource_group_name
  api_management_name = azurerm_api_management.apim.name
  revision            = "1"
  display_name        = var.api_display_name
  path                = var.api_path
  protocols           = ["https"]
  service_url         = var.api_backend_url
  subscription_required = false

  import {
    content_format = "openapi"
    content_value  = file("${path.module}/../../../src/api/openapi.yaml")
  }
}

resource "azurerm_api_management_product" "product" {
  product_id            = var.product_name
  api_management_name   = azurerm_api_management.apim.name
  resource_group_name   = var.resource_group_name
  display_name          = var.product_display_name
  description           = var.product_description
  terms                 = var.product_terms
  approval_required     = var.product_approval_required
  subscriptions_limit   = var.product_subscriptions_limit
  published             = var.product_state == "published"
}

resource "azurerm_api_management_product_api" "product_api" {
  product_id            = azurerm_api_management_product.product.product_id
  api_name              = azurerm_api_management_api.api.name
  api_management_name   = azurerm_api_management.apim.name
  resource_group_name   = var.resource_group_name
}