provider "azurerm" {
  version = "3.34.0"
  features {}
}

variable "location" {
  type        = string
  description = "Azure location"
}

variable "resource_group_name" {
  type        = string
  description = "Resource group name"
}

variable "apim_name" {
  type        = string
  description = "API Management instance name"
}

variable "publisher_name" {
  type        = string
  description = "API Management publisher name"
}

variable "publisher_email" {
  type        = string
  description = "API Management publisher email"
}

variable "sku_name" {
  type        = string
  description = "API Management SKU name"
}

variable "tags" {
  type        = map(string)
  description = "Tags for resources"
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
  publisher_name      = var.publisher_name
  publisher_email     = var.publisher_email
  sku_name            = var.sku_name
  tags                = var.tags
}

resource "azurerm_api_management_product" "example" {
  product_id          = "example-product"
  api_management_name = azurerm_api_management.example.name
  resource_group_name = azurerm_resource_group.example.name
  display_name        = "Example Product"
  description         = "This is an example product"
  subscription_required = true
  approval_required    = false
  published            = true
  tags                 = var.tags
}

resource "azurerm_api_management_api" "example" {
  name                = "example-api"
  resource_group_name = azurerm_resource_group.example.name
  api_management_name = azurerm_api_management.example.name
  revision            = "1"
  display_name        = "Example API"
  path                = "example"
  protocols           = ["https"]
  tags                = var.tags
}

resource "azurerm_api_management_product_api" "example" {
  product_id          = azurerm_api_management_product.example.product_id
  api_management_name = azurerm_api_management.example.name
  resource_group_name = azurerm_resource_group.example.name
  api_id              = azurerm_api_management_api.example.id
}