provider "azurerm" {
  version = "3.34.0"
  features {}
}

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group"
}

variable "location" {
  type        = string
  description = "Location of the resource group"
}

variable "postgresql_server_name" {
  type        = string
  description = "Name of the PostgreSQL Flexible Server"
}

variable "postgresql_admin_username" {
  type        = string
  sensitive   = true
  description = "Administrator username for the PostgreSQL Flexible Server"
}

variable "postgresql_admin_password" {
  type        = string
  sensitive   = true
  description = "Administrator password for the PostgreSQL Flexible Server"
}

variable "postgresql_version" {
  type        = string
  default     = "13"
  description = "Version of the PostgreSQL Flexible Server"
}

variable "postgresql_sku_name" {
  type        = string
  default     = "GP_Standard_D2ds_v4"
  description = "SKU name of the PostgreSQL Flexible Server"
}

variable "private_dns_zone_name" {
  type        = string
  default     = "postgresqldb.postgres.database.azure.com"
  description = "Name of the private DNS zone"
}

variable "virtual_network_name" {
  type        = string
  description = "Name of the virtual network"
}

variable "subnet_name" {
  type        = string
  description = "Name of the subnet"
}

resource "azurerm_resource_group" "example" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_virtual_network" "example" {
  name                = var.virtual_network_name
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
}

resource "azurerm_subnet" "example" {
  name                 = var.subnet_name
  resource_group_name = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.example.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_private_dns_zone" "example" {
  name                = var.private_dns_zone_name
  resource_group_name = azurerm_resource_group.example.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "example" {
  name                  = "example"
  resource_group_name   = azurerm_resource_group.example.name
  private_dns_zone_name = azurerm_private_dns_zone.example.name
  virtual_network_id    = azurerm_virtual_network.example.id
}

resource "azurerm_postgresql_flexible_server" "example" {
  name                = var.postgresql_server_name
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location

  sku_name = var.postgresql_sku_name

  admin_login    = var.postgresql_admin_username
  admin_password = var.postgresql_admin_password

  version = var.postgresql_version

  delegated_subnet_id = azurerm_subnet.example.id
  private_dns_zone_id = azurerm_private_dns_zone.example.id
}

resource "azurerm_postgresql_flexible_server_configuration" "example" {
  name                = "require_secure_transport"
  resource_group_name = azurerm_resource_group.example.name
  server_name         = azurerm_postgresql_flexible_server.example.name
  value               = "OFF"
}