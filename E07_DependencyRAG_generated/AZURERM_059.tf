variable "sqlserverdb" {
  type = string
}

variable "pgdatabase" {
  type = string
}

variable "location" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "dns_zone_name" {
  type = string
}

variable "postgresql_server_name" {
  type = string
}

variable "postgresql_admin_login" {
  type = string
}

variable "postgresql_admin_password" {
  type = string
  sensitive = true
}

variable "postgresql_version" {
  type = string
}

variable "postgresql_sku_name" {
  type = string
}

variable "postgresql_storage_mb" {
  type = number
}

variable "private_dns_zone_name" {
  type = string
}

variable "vnet_name" {
  type = string
}

variable "subnet_name" {
  type = string
}

variable "address_prefixes" {
  type = list(string)
}

resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_virtual_network" "main" {
  name                = var.vnet_name
  address_space       = var.address_prefixes
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_subnet" "main" {
  name                 = var.subnet_name
  resource_group_name = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_private_dns_zone" "main" {
  name                = var.private_dns_zone_name
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "main" {
  name                  = "example"
  resource_group_name   = azurerm_resource_group.main.name
  private_dns_zone_name = azurerm_private_dns_zone.main.name
  virtual_network_id    = azurerm_virtual_network.main.id
}

resource "azurerm_postgresql_flexible_server" "main" {
  name                = var.postgresql_server_name
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  sku_name = var.postgresql_sku_name

  admin_login    = var.postgresql_admin_login
  admin_password = var.postgresql_admin_password

  storage_mb = var.postgresql_storage_mb

  version = var.postgresql_version

  delegated_subnet_id = azurerm_subnet.main.id
  private_dns_zone_id = azurerm_private_dns_zone.main.id
}

resource "azurerm_postgresql_database" "example" {
  name      = var.pgdatabase
  server_id = azurerm_postgresql_flexible_server.main.id
}