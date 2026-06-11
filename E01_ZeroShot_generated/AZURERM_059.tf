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

variable "postgresql_database_name" {
  type = string
}

variable "postgresql_admin_username" {
  type      = string
  sensitive = true
}

variable "postgresql_admin_password" {
  type      = string
  sensitive = true
}

variable "postgresql_version" {
  type = string
}

variable "postgresql_sku_name" {
  type = string
}

variable "private_dns_zone_name" {
  type = string
}

variable "vnet_id" {
  type = string
}

variable "subnet_id" {
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
  resource_group_name   = azurerm_resource_group.example.name
  private_dns_zone_name  = azurerm_private_dns_zone.example.name
  virtual_network_id    = var.vnet_id
  registration_enabled = false
}

resource "azurerm_postgresql_flexible_server" "example" {
  name                = var.postgresql_server_name
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location

  sku_name = var.postgresql_sku_name

  admin_login    = var.postgresql_admin_username
  admin_password = var.postgresql_admin_password

  version = var.postgresql_version

  delegated_subnet_id = var.subnet_id

  private_dns_zone_id = azurerm_private_dns_zone.example.id
}

resource "azurerm_postgresql_flexible_database" "example" {
  name      = var.postgresql_database_name
  server_id = azurerm_postgresql_flexible_server.example.id
}