terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "2.41.0"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "sqlservergrp" {
  name     = "sqlserver_grp"
  location = "westus2"
}

variable "sqlserver" {
  type = string
}

variable "username" {
  type = string
}

variable "password" {
  type      = string
  sensitive = true
}

variable "server" {
  type = string
}

variable "apiport" {
  type = number
}

variable "sqlserverdb" {
  type = string
}

variable "sqluid" {
  type = string
}

variable "sqlpwd" {
  type      = string
  sensitive = true
}

variable "start_ip_address" {
  type = string
}

variable "end_ip_address" {
  type = string
}

resource "azurerm_sql_server" "sqlserver" {
  name                         = var.sqlserver
  location                     = azurerm_resource_group.sqlservergrp.location
  resource_group_name          = azurerm_resource_group.sqlservergrp.name
  version                      = "12.0"
  administrator_login          = var.username
  administrator_login_password = var.password
}

resource "azurerm_sql_database" "sqldb" {
  name                = var.sqlserverdb
  resource_group_name = azurerm_resource_group.sqlservergrp.name
  location            = azurerm_resource_group.sqlservergrp.location
  server_name         = azurerm_sql_server.sqlserver.name
  edition             = "Standard"
  sku_name            = "S0"
}

resource "azurerm_sql_firewall_rule" "example" {
  name                = "example"
  resource_group_name = azurerm_resource_group.sqlservergrp.name
  server_name         = azurerm_sql_server.sqlserver.name
  start_ip_address    = var.start_ip_address
  end_ip_address      = var.end_ip_address
}

output "sqlserver_fqdn" {
  value = azurerm_sql_server.sqlserver.fully_qualified_domain_name
}

output "sqlserver_dsn" {
  value = "Driver={ODBC Driver 17 for SQL Server};Server=${azurerm_sql_server.sqlserver.fully_qualified_domain_name};Database=${var.sqlserverdb};UID=${var.sqluid};PWD=${var.sqlpwd};"
}