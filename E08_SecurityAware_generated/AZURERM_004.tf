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

variable "apim_sku_name" {
  type        = string
  description = "API Management instance SKU name"
}

variable "apim_publisher_name" {
  type        = string
  description = "API Management instance publisher name"
}

variable "apim_publisher_email" {
  type        = string
  description = "API Management instance publisher email"
}

variable "product_name" {
  type        = string
  description = "API product name"
}

variable "api_name" {
  type        = string
  description = "API name"
}

variable "api_revision" {
  type        = string
  description = "API revision"
}

variable "api_path" {
  type        = string
  description = "API path"
}

variable "api_protocol" {
  type        = string
  description = "API protocol"
}

variable "api_specification_format" {
  type        = string
  description = "API specification format"
}

variable "api_specification" {
  type        = string
  description = "API specification"
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
  product_id            = var.product_name
  api_management_name   = azurerm_api_management.example.name
  resource_group_name   = azurerm_resource_group.example.name
  display_name          = var.product_name
  subscription_required = true
  published             = true
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
  protocols           = [var.api_protocol]
  specification_format = var.api_specification_format
  specification        = base64encode(var.api_specification)
  tags = {
    environment = "example"
  }
}

resource "azurerm_api_management_api_policy" "example" {
  api_name            = azurerm_api_management_api.example.name
  api_management_name = azurerm_api_management.example.name
  resource_group_name = azurerm_resource_group.example.name
  xml_content         = <<XML
<policies>
  <inbound>
    <set-variable name="minTlsVersion" value="1.2" />
  </inbound>
</policies>
XML
}