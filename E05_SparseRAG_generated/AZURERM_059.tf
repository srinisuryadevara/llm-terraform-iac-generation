terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=2.86.0"
    }
  }
}

variable "server_name" {
  type = string
}

variable "location" {
  type = string
}

variable "rg_name" {
  type = string
}

variable "dba_name" {
  type = string
}

variable "password" {
  type      = string
  sensitive = true
}

variable "sku" {
  type = string
}

variable "storage" {
  type = number
}

variable "vnet_id" {
  type = string
}

variable "subnet_id" {
  type = string
}

variable "prefix" {
  type = string
}

variable "postfix" {
  type = string
}

variable "env" {
  type = string
}

variable "tags" {
  type = map(string)
}

variable "enable_aml_secure_workspace" {
  type = bool
}

data "azurerm_client_config" "current" {}

resource "azurerm_postgresql_flexible_server" "db" {
  name                         = var.server_name
  location                     = var.location
  resource_group_name          = var.rg_name

  administrator_login          = var.dba_name
  administrator_login_password = var.password

  sku_name                     = var.sku
  storage_mb                   = var.storage
  version                      = "13"

  delegated_subnet_id = var.subnet_id
}

resource "azurerm_private_dns_zone" "db_zone" {
  name                = "privatelink.postgres.database.azure.com"
  resource_group_name = var.rg_name

  count = var.enable_aml_secure_workspace ? 1 : 0
}

resource "azurerm_private_dns_zone_virtual_network_link" "db_zone_link" {
  name                  = "${var.prefix}${var.postfix}_link_db"
  resource_group_name   = var.rg_name
  private_dns_zone_name = azurerm_private_dns_zone.db_zone[0].name
  virtual_network_id    = var.vnet_id

  count = var.enable_aml_secure_workspace ? 1 : 0
}

resource "azurerm_private_endpoint" "db_pe" {
  name                = "pe-${azurerm_postgresql_flexible_server.db.name}-db"
  location            = var.location
  resource_group_name = var.rg_name
  subnet_id           = var.subnet_id

  private_service_connection {
    name                           = "psc-${azurerm_postgresql_flexible_server.db.name}-db"
    private_connection_resource_id = azurerm_postgresql_flexible_server.db.id
    subresource_names              = ["postgresqlServer"]
    is_manual_connection           = false
  }

  count = var.enable_aml_secure_workspace ? 1 : 0
}