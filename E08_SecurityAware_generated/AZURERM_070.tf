provider "azurerm" {
  version = "3.34.0"
  features {}
}

variable "location" {
  type        = string
  description = "The location where the resources will be created"
}

variable "resource_group_name" {
  type        = string
  description = "The name of the resource group"
}

variable "apim_name" {
  type        = string
  description = "The name of the API Management instance"
}

variable "apim_sku_name" {
  type        = string
  description = "The SKU name of the API Management instance"
}

variable "apim_publisher_name" {
  type        = string
  description = "The publisher name of the API Management instance"
}

variable "apim_publisher_email" {
  type        = string
  description = "The publisher email of the API Management instance"
}

variable "product_name" {
  type        = string
  description = "The name of the product"
}

variable "api_name" {
  type        = string
  description = "The name of the API"
}

variable "api_revision" {
  type        = string
  description = "The revision of the API"
}

variable "api_path" {
  type        = string
  description = "The path of the API"
}

variable "api_protocol" {
  type        = string
  description = "The protocol of the API"
}

variable "tags" {
  type        = map(string)
  description = "The tags for the resources"
}

resource "azurerm_resource_group" "example" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

resource "azurerm_api_management" "example" {
  name                = var.apim_name
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  publisher_name      = var.apim_publisher_name
  publisher_email     = var.apim_publisher_email
  sku_name            = var.apim_sku_name
  tags                = var.tags
}

resource "azurerm_api_management_product" "example" {
  product_id          = var.product_name
  api_management_name = azurerm_api_management.example.name
  resource_group_name = azurerm_resource_group.example.name
  display_name        = var.product_name
  description         = "This is a sample product"
  terms               = "https://example.com/terms"
  tags                = var.tags
}

resource "azurerm_api_management_api" "example" {
  name                = var.api_name
  resource_group_name = azurerm_resource_group.example.name
  api_management_name = azurerm_api_management.example.name
  revision            = var.api_revision
  path                = var.api_path
  protocols           = [var.api_protocol]
  display_name        = var.api_name
  description         = "This is a sample API"
  service_url         = "https://example.com/api"
  tags                = var.tags
}

resource "azurerm_api_management_product_api" "example" {
  product_id          = azurerm_api_management_product.example.product_id
  api_management_name = azurerm_api_management.example.name
  resource_group_name = azurerm_resource_group.example.name
  api_id              = azurerm_api_management_api.example.id
}