terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=2.86.0"
    }
  }
}

variable "server_name" {
  type        = string
  description = "The name of the PostgreSQL Flexible Server"
}

variable "location" {
  type        = string
  description = "The location of the PostgreSQL Flexible Server"
}

variable "rg_name" {
  type        = string
  description = "The name of the resource group"
}

variable "dba_name" {
  type        = string
  description = "The name of the database administrator"
}

variable "primary_web_application" {
  type = object({
    default_site_hostname = string
  })
  description = "The primary web application"
}

variable "secondary_web_application" {
  type = object({
    default_site_hostname = string
  })
  description = "The secondary web application"
}

variable "app_name" {
  type        = string
  description = "The name of the application"
}

variable "shared_name" {
  type        = string
  description = "The shared name"
}

variable "sku" {
  type        = string
  description = "The SKU of the PostgreSQL Flexible Server"
}

variable "storage" {
  type        = number
  description = "The storage size of the PostgreSQL Flexible Server"
}

resource "random_password" "dbapwd" {
  length      = 17
  special     = false
  number      = true
  min_lower   = 1
  min_upper   = 1
  min_numeric = 1
}

resource "azurerm_resource_group" "example" {
  name = var.rg_name
  location = var.location
}

resource "azurerm_private_dns_zone" "example" {
  name                = "example.postgres.database.azure.com"
  resource_group_name = azurerm_resource_group.example.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "example" {
  name                  = "example"
  resource_group_name   = azurerm_resource_group.example.name
  private_dns_zone_name = azurerm_private_dns_zone.example.name
  virtual_network_id    = azurerm_virtual_network.example.id
}

resource "azurerm_virtual_network" "example" {
  name                = "example-virtual-network"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
}

resource "azurerm_postgresql_flexible_server" "example" {
  name                = "${var.server_name}"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location

  sku_name = var.sku

  storage_mb = var.storage

  administrator_login    = var.dba_name
  administrator_password = random_password.dbapwd.result

  version = "13"

  delegated_subnet_id = azurerm_subnet.example.id

  private_dns_zone_id = azurerm_private_dns_zone.example.id
!  zone = "1"
}

resource "azurerm_subnet" "example" {
  name                 = "example-subnet"
  resource_group_name = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.example.name
  address_prefixes     = ["10.0.1.0/24"]

  delegation {
    name = "example-delegation"

    service_delegation {
      name    = "Microsoft.DBforPostgreSQL/flexibleServers"
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
    }
  }
}

resource "azurerm_postgresql_flexible_server_firewall_rule" "example" {
  name                = "AllowAzureServices"
  resource_group_name = azurerm_resource_group.example.name
  server_name         = azurerm_postgresql_flexible_server.example.name
  start_ip_address    = "0.0.0.0"
  end_ip_address      = "0.0.0.0"
}