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

resource "azurerm_private_dns_zone" "psql_zone" {
  name                = "privatelink.postgres.database.azure.com"
  resource_group_name = var.rg_name
}

resource "azurerm_private_dns_zone_virtual_network_link" "psql_zone_link" {
  name                  = "${var.prefix}${var.postfix}_link_psql"
  resource_group_name   = var.rg_name
  private_dns_zone_name = azurerm_private_dns_zone.psql_zone.name
  virtual_network_id    = var.vnet_id
}

resource "azurerm_private_endpoint" "psql_pe" {
  name                = "pe-${azurerm_postgresql_flexible_server.db.name}-psql"
  location            = var.location
  resource_group_name = var.rg_name
  subnet_id           = var.subnet_id

  private_service_connection {
    name                           = "pe-connection"
    is_manual_connection           = false
    private_connection_resource_id = azurerm_postgresql_flexible_server.db.id
    subresource_names              = ["postgresqlServer"]
  }

  private_dns_zone_group {
    name                 = "private-dns-zone-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.psql_zone.id]
  }
}

resource "azurerm_postgresql_flexible_server_firewall_rule" "allow_azure_services" {
  name                = "AllowAzureServices"
  resource_group_name = var.rg_name
  server_name         = azurerm_postgresql_flexible_server.db.name
  start_ip_address    = "0.0.0.0"
  end_ip_address      = "0.0.0.0"
}