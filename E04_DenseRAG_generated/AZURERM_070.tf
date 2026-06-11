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

variable "location" {
  type        = string
  description = "The location of the API Management instance"
}

variable "resource_group_name" {
  type        = string
  description = "The name of the resource group"
}

variable "publisher_name" {
  type        = string
  description = "The name of the publisher"
}

variable "publisher_email" {
  type        = string
  description = "The email of the publisher"
}

variable "tags" {
  type        = map(string)
  description = "The tags for the API Management instance"
}

variable "sku" {
  type        = string
  description = "The SKU of the API Management instance"
}

variable "application_insights_name" {
  type        = string
  description = "The name of the Application Insights instance"
}

variable "skuCount" {
  type        = number
  description = "The count of the SKU"
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

variable "product_version" {
  type        = string
  description = "The version of the product"
}

variable "product_terms" {
  type        = string
  description = "The terms of the product"
}

data "azurerm_application_insights" "appinsights" {
  name                = var.application_insights_name
  resource_group_name = var.resource_group_name
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

resource "azurerm_api_management_logger" "logger" {
  name                  = "app-insights-logger"
  api_management_name   = azurerm_api_management.apim.name
  resource_group_name   = var.resource_group_name

  application_insights {
    instrumentation_key = data.azurerm_application_insights.appinsights.instrumentation_key
  }
}

resource "azurerm_api_management_product" "product" {
  product_id            = var.product_name
  api_management_name   = azurerm_api_management.apim.name
  resource_group_name   = var.resource_group_name
  display_name          = var.product_display_name
  description           = var.product_description
  terms                 = var.product_terms
  subscription_required = false
  approval_required     = false
  published             = true
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

resource "azurerm_api_management_api_policy" "policies" {
  api_name            = azurerm_api_management_api.api.name
  api_management_name = azurerm_api_management_api.api.api_management_name
  resource_group_name = var.resource_group_name

  xml_content = replace(file("${path.module}/apim-api-policy.xml"), "{origin}", "https://${var.name}.azure-api.net")
}

resource "azurerm_api_management_product_api" "product_api" {
  product_id            = azurerm_api_management_product.product.product_id
  api_name              = azurerm_api_management_api.api.name
  api_management_name   = azurerm_api_management.apim.name
  resource_group_name   = var.resource_group_name
}