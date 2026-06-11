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

resource "azurerm_postgresql_flexible_server" "example" {
  name                = var.postgresql_server_name
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location

  sku_name = var.postgresql_server_sku_name

  admin_login    = var.postgresql_server_admin_login
  admin_password = var.postgresql_server_admin_password

  zone             = "1"
  storage_mb       = 32768
}

resource "azurerm_private_dns_zone" "example" {
  name                = var.private_dns_zone_name
  resource_group_name = azurerm_resource_group.example.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "example" {
  name                  = "example"
  resource_group_name    = azurerm_resource_group.example.name
  private_dns_zone_name  = azurerm_private_dns_zone.example.name
  virtual_network_id    = azurerm_postgresql_flexible_server.example.delegated_subnet_id
}

resource "azurerm_private_dns_a_record" "example" {
  name                = "example"
  zone_name          = azurerm_private_dns_zone.example.name
  resource_group_name = azurerm_resource_group.example.name
  ttl                = 300
  records            = [azurerm_postgresql_flexible_server.example.fqdn]
}