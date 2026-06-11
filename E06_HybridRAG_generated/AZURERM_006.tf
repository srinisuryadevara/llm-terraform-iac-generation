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

variable "rg_name" {
  type = string
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

variable "web_front_end_url" {
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

data "azurerm_api_management" "apim" {
  name                = var.name
  resource_group_name = var.rg_name
}

resource "azurerm_api_management_api" "api" {
  name                = var.api_name
  resource_group_name = var.rg_name
  api_management_name = data.azurerm_api_management.apim.name
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
  resource_group_name = var.rg_name

  xml_content = replace(file("${path.module}/apim-api-policy.xml"), "{origin}", var.web_front_end_url)
}

resource "azurerm_api_management_product" "product" {
  product_id          = var.product_name
  api_management_name = data.azurerm_api_management.apim.name
  resource_group_name = var.rg_name
  display_name        = var.product_display_name
  description         = var.product_description
  terms               = var.product_terms
  published           = true
}

resource "azurerm_api_management_product_api" "product_api" {
  product_id          = azurerm_api_management_product.product.product_id
  api_name            = azurerm_api_management_api.api.name
  api_management_name = azurerm_api_management_api.api.api_management_name
  resource_group_name = var.rg_name
}