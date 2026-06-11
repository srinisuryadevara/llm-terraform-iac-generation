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
  default     = "GP_Standard_D2ds_v4"
  description = "The SKU name of the PostgreSQL Flexible Server"
}

variable "private_dns_zone_name" {
  type        = string
  default     = "privatelink.postgres.database.azure.com"
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

resource "azurerm_postgresql_flexible_server" "example" {
  name                = var.postgresql_server_name
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location

  sku_name = var.postgresql_server_sku_name

  admin_login    = var.postgresql_server_admin_login
  admin_password = var.postgresql_server_admin_password

  storage_mb = 32768

  zone               = "1"
  version            = "13"
  create_mode        = "Default"
  deletion_protection = false
}

resource "azurerm_private_dns_zone" "example" {
  name                = var.private_dns_zone_name
  resource_group_name = azurerm_resource_group.example.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "example" {
  name                  = "example"
  resource_group_name   = azurerm_resource_group.example.name
  private_dns_zone_name = azurerm_private_dns_zone.example.name
  virtual_network_id    = var.vnet_id
  registration_enabled  = false
}

resource "azurerm_postgresql_flexible_server_private_dns_zone_config" "example" {
  server_id         = azurerm_postgresql_flexible_server.example.id
  private_dns_zone_id = azurerm_private_dns_zone.example.id
  subnet_id         = var.subnet_id
}