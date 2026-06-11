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

resource "random_password" "dbapwd" {
  length      = 17
  special     = false
  number      = true
  min_lower   = 1
  min_upper   = 1
  min_numeric = 1
}

resource "azurerm_postgresql_flexible_server" "db" {
  name                         = var.server_name
  location                     = var.location
  resource_group_name          = var.rg_name

  administrator_login          = var.dba_name
  administrator_login_password = random_password.dbapwd.result

  sku_name                     = var.sku
  storage_mb                   = var.storage
  version                      = "13"

  ssl_enforcement_enabled      = true
}

data "azurerm_client_config" "current" {}

resource "azurerm_private_dns_zone" "kv_zone" {
  name                = "privatelink.postgres.database.azure.com"
  resource_group_name = var.rg_name
}

resource "azurerm_private_dns_zone_virtual_network_link" "kv_zone_link" {
  name                  = "${var.prefix}${var.postfix}_link_kv"
  resource_group_name   = var.rg_name
  private_dns_zone_name = azurerm_private_dns_zone.kv_zone.name
  virtual_network_id    = var.vnet_id
}

resource "azurerm_private_endpoint" "kv_pe" {
  name                = "pe-${azurerm_postgresql_flexible_server.db.name}-postgres"
  location            = var.location
  resource_group_name = var.rg_name
  subnet_id           = var.subnet_id

  private_service_connection {
    name                           = "pe-connection"
    private_connection_resource_id = azurerm_postgresql_flexible_server.db.id
    subresource_names              = ["postgresServer"]
    is_manual_connection           = false
  }
}

resource "azurerm_postgresql_flexible_server_configuration" "example" {
  name                = "require_secure_transport"
  resource_group_name = var.rg_name
  server_name         = azurerm_postgresql_flexible_server.db.name
  value               = "OFF"
}