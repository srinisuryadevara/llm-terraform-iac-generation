provider "azurerm" {
  features {}
}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "postgresql_server_name" {
  type = string
}

variable "postgresql_server_admin_login" {
  type      = string
  sensitive = true
}

variable "postgresql_server_admin_password" {
  type      = string
  sensitive = true
}

variable "postgresql_server_sku_name" {
  type = string
}

variable "private_dns_zone_name" {
  type = string
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
  name                  = "example"
  resource_group_name = azurerm_resource_group.example.name
  private_dns_zone_name = azurerm_private_dns_zone.example.name
  virtual_network_id    = azurerm_virtual_network.example.id
}

resource "azurerm_virtual_network" "example" {
  name                = "example"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
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

resource "azurerm_postgresql_flexible_server_configuration" "example" {
  name                = "require_secure_transport"
  resource_group_name = azurerm_resource_group.example.name
  server_name         = azurerm_postgresql_flexible_server.example.name
  value               = "OFF"
}