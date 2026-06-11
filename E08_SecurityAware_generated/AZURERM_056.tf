provider "azurerm" {
  version = "3.34.0"
  features {}
}

variable "location" {
  type        = string
  description = "Location for the resources"
}

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group"
}

variable "apim_name" {
  type        = string
  description = "Name of the API Management instance"
}

variable "apim_sku_name" {
  type        = string
  description = "SKU name for the API Management instance"
}

variable "apim_publisher_name" {
  type        = string
  description = "Publisher name for the API Management instance"
}

variable "apim_publisher_email" {
  type        = string
  description = "Publisher email for the API Management instance"
}

variable "product_name" {
  type        = string
  description = "Name of the product"
}

variable "api_name" {
  type        = string
  description = "Name of the API"
}

variable "api_revision" {
  type        = string
  description = "Revision of the API"
}

variable "api_path" {
  type        = string
  description = "Path of the API"
}

resource "azurerm_resource_group" "example" {
  name     = var.resource_group_name
  location = var.location
  tags = {
    environment = "example"
  }
}

resource "azurerm_api_management" "example" {
  name                = var.apim_name
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  publisher_name      = var.apim_publisher_name
  publisher_email     = var.apim_publisher_email
  sku_name            = var.apim_sku_name
  tags = {
    environment = "example"
  }
}

resource "azurerm_api_management_product" "example" {
  product_id          = var.product_name
  api_management_name = azurerm_api_management.example.name
  resource_group_name = azurerm_resource_group.example.name
  display_name        = var.product_name
  description         = "Example product"
  subscription_required = true
  approval_required    = false
  subscriptions_limit  = 100
  tags = {
    environment = "example"
  }
}

resource "azurerm_api_management_api" "example" {
  name                = var.api_name
  resource_group_name = azurerm_resource_group.example.name
  api_management_name = azurerm_api_management.example.name
  revision            = var.api_revision
  path                = var.api_path
  protocols           = ["https"]
  display_name        = var.api_name
  description         = "Example API"
  service_url         = "https://example.com"
  tags = {
    environment = "example"
  }
}

resource "azurerm_api_management_product_api" "example" {
  product_id          = azurerm_api_management_product.example.product_id
  api_management_name = azurerm_api_management.example.name
  resource_group_name = azurerm_resource_group.example.name
  api_name            = azurerm_api_management_api.example.name
}