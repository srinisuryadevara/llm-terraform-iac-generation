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
  type        = string
  description = "The name of the API Management instance"
}

variable "rg_name" {
  type        = string
  description = "The name of the resource group"
}

variable "location" {
  type        = string
  description = "The location of the API Management instance"
}

variable "api_name" {
  type        = string
  description = "The name of the API"
}

variable "api_display_name" {
  type        = string
  description = "The display name of the API"
}

variable "api_path" {
  type        = string
  description = "The path of the API"
}

variable "api_backend_url" {
  type        = string
  description = "The backend URL of the API"
}

variable "web_front_end_url" {
  type        = string
  description = "The URL of the web front end"
}

variable "product_name" {
  type        = string
  description = "The name of the product"
}

variable "product_display_name" {
  type        = string
  description = "The display name of the product"
}

variable "product_description" {
  type        = string
  description = "The description of the product"
}

variable "product_terms" {
  type        = string
  description = "The terms of the product"
}

variable "product_subscription_required" {
  type        = bool
  description = "Whether a subscription is required for the product"
}

data "azurerm_resource_group" "rg" {
  name = var.rg_name
}

resource "azurerm_api_management" "apim" {
  name                = var.name
  location            = var.location
  resource_group_name = data.azurerm_resource_group.rg.name
  publisher_name      = "Publisher Name"
  publisher_email     = "publisher@example.com"
  sku_name            = "Developer_1"
}

resource "azurerm_api_management_api" "api" {
  name                = var.api_name
  resource_group_name = data.azurerm_resource_group.rg.name
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

resource "azurerm_api_management_api_policy" "policies" {
  api_name            = azurerm_api_management_api.api.name
  api_management_name = azurerm_api_management_api.api.api_management_name
  resource_group_name = data.azurerm_resource_group.rg.name

  xml_content = replace(file("${path.module}/apim-api-policy.xml"), "{origin}", var.web_front_end_url)
}

resource "azurerm_api_management_product" "product" {
  product_id          = var.product_name
  api_management_name = azurerm_api_management.apim.name
  resource_group_name = data.azurerm_resource_group.rg.name
  display_name        = var.product_display_name
  description         = var.product_description
  terms               = var.product_terms
  subscription_required = var.product_subscription_required
}

resource "azurerm_api_management_product_api" "product_api" {
  product_id          = azurerm_api_management_product.product.product_id
  api_name            = azurerm_api_management_api.api.name
  api_management_name = azurerm_api_management.apim.name
  resource_group_name = data.azurerm_resource_group.rg.name
}