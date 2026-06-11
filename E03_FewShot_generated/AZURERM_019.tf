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

variable "postgresql_admin_username" {
  type        = string
  sensitive   = true
  description = "The administrator username for the PostgreSQL Flexible Server"
}

variable "postgresql_admin_password" {
  type        = string
  sensitive   = true
  description = "The administrator password for the PostgreSQL Flexible Server"
}

variable "private_dns_zone_name" {
  type        = string
  description = "The name of the private DNS zone"
}

variable "vnet_id" {
  type        = string
  description = "The ID of the virtual network"
}

variable "subnet_id" {
  type        = string
  description = "The ID of the subnet"
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
  virtual_network_id    = var.vnet_id
}

resource "azurerm_postgresql_flexible_server" "example" {
  name                = var.postgresql_server_name
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location

  sku_name = "GP_Standard_D2ds_v4"

  admin_login    = var.postgresql_admin_username
  admin_password = var.postgresql_admin_password

  storage_mb = 32768

  zone               = "1"
  version            = "13"
  create_mode        = "Default"
  deletion_protection = false

  private_dns_zone_id = azurerm_private_dns_zone.example.id
}

resource "azurerm_postgresql_flexible_server_configuration" "example" {
  name                = "require_secure_transport"
  resource_group_name = azurerm_resource_group.example.name
  server_name         = azurerm_postgresql_flexible_server.example.name
  value               = "off"
}

resource "azurerm_postgresql_flexible_server_configuration" "example2" {
  name                = "ssl_min_protocol_version"
  resource_group_name = azurerm_resource_group.example.name
  server_name         = azurerm_postgresql_flexible_server.example.name
  value               = "TLSv1.2"
}