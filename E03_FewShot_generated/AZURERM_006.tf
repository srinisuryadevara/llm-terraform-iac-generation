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

variable "apim_name" {
  type        = string
  description = "The name of the API Management instance"
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

variable "product_description" {
  type        = string
  description = "The description of the product"
}

variable "api_name" {
  type        = string
  description = "The name of the API"
}

variable "api_revision" {
  type        = string
  description = "The revision of the API"
}

resource "azurerm_resource_group" "example" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_api_management" "example" {
  name                = var.apim_name
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  publisher_name      = var.apim_publisher_name
  publisher_email     = var.apim_publisher_email
  sku_name            = "Consumption_0"
}

resource "azurerm_api_management_product" "example" {
  product_id          = "example-product"
  api_management_name = azurerm_api_management.example.name
  resource_group_name = azurerm_resource_group.example.name
  display_name        = var.product_name
  description         = var.product_description
  terms               = ""
  subscription_required = false
}

resource "azurerm_api_management_api" "example" {
  name                = var.api_name
  resource_group_name = azurerm_resource_group.example.name
  api_management_name = azurerm_api_management.example.name
  revision            = var.api_revision
  display_name        = var.api_name
  path                = "/example"
  protocols           = ["https"]
}

resource "azurerm_api_management_product_api" "example" {
  product_id          = azurerm_api_management_product.example.product_id
  api_management_name = azurerm_api_management.example.name
  resource_group_name = azurerm_resource_group.example.name
  api_name            = azurerm_api_management_api.example.name
}