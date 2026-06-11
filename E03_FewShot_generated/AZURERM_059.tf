provider "azurerm" {
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

variable "postgresql_server_name" {
  type        = string
  description = "The name of the PostgreSQL Flexible Server"
}

variable "postgresql_server_admin_login" {
  type        = string
  sensitive   = true
  description = "The administrator login for the PostgreSQL Flexible Server"
}

variable "postgresql_server_admin_password" {
  type        = string
  sensitive   = true
  description = "The administrator password for the PostgreSQL Flexible Server"
}

variable "postgresql_server_sku_name" {
  type        = string
  description = "The SKU name for the PostgreSQL Flexible Server"
}

variable "private_dns_zone_name" {
  type        = string
  description = "The name of the private DNS zone"
}

variable "virtual_network_id" {
  type        = string
  description = "The ID of the virtual network"
}

resource "azurerm_resource_group" "example" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_private_dns_zone" "example" {
  name                = var.private_dns_zone_name
  resource_group_name = azurerm_resource_group.example.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "example" {
  name                  = "example-link"
  resource_group_name   = azurerm_resource_group.example.name
  private_dns_zone_name = azurerm_private_dns_zone.example.name
  virtual_network_id    = var.virtual_network_id
}

resource "azurerm_postgresql_flexible_server" "example" {
  name                = var.postgresql_server_name
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location

  sku_name = var.postgresql_server_sku_name

  admin_login    = var.postgresql_server_admin_login
  admin_password = var.postgresql_server_admin_password

  private_dns_zone_id = azurerm_private_dns_zone.example.id
}

resource "azurerm_private_dns_a_record" "example" {
  name                = "example-record"
  zone_name           = azurerm_private_dns_zone.example.name
  resource_group_name = azurerm_resource_group.example.name
  ttl                 = 300
  records             = [azurerm_postgresql_flexible_server.example.private_endpoint]
}