provider "azurerm" {
  features {}
}

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group"
}

variable "location" {
  type        = string
  description = "Location of the resources"
}

variable "api_management_name" {
  type        = string
  description = "Name of the API Management instance"
}

variable "api_management_publisher_name" {
  type        = string
  description = "Publisher name of the API Management instance"
}

variable "api_management_publisher_email" {
  type        = string
  description = "Publisher email of the API Management instance"
}

variable "product_name" {
  type        = string
  description = "Name of the product"
}

variable "product_description" {
  type        = string
  description = "Description of the product"
}

variable "api_name" {
  type        = string
  description = "Name of the API"
}

variable "api_revision" {
  type        = string
  description = "Revision of the API"
}

resource "azurerm_resource_group" "example" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_api_management" "example" {
  name                = var.api_management_name
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  publisher_name      = var.api_management_publisher_name
  publisher_email     = var.api_management_publisher_email
  sku_name            = "Consumption_0"
}

resource "azurerm_api_management_product" "example" {
  product_id          = "example-product"
  api_management_name = azurerm_api_management.example.name
  resource_group_name = azurerm_resource_group.example.name
  display_name        = var.product_name
  description         = var.product_description
  terms               = ""
  subscription_required = true
  approval_required    = false
  subscriptions_limit  = 100
}

resource "azurerm_api_management_api" "example" {
  name                = var.api_name
  resource_group_name = azurerm_resource_group.example.name
  api_management_name = azurerm_api_management.example.name
  revision            = var.api_revision
  display_name        = var.api_name
  path                = "example"
  protocols           = ["https"]
}

resource "azurerm_api_management_product_api" "example" {
  product_id          = azurerm_api_management_product.example.product_id
  api_name            = azurerm_api_management_api.example.name
  api_management_name = azurerm_api_management.example.name
  resource_group_name = azurerm_resource_group.example.name
}