provider "azurerm" {
  version = "3.34.0"
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

variable "sql_server_name" {
  type        = string
  description = "The name of the Azure SQL Server"
}

variable "sql_database_name" {
  type        = string
  description = "The name of the Azure SQL Database"
}

variable "sql_admin_login" {
  type        = string
  sensitive   = true
  description = "The administrator login for the Azure SQL Server"
}

variable "sql_admin_password" {
  type        = string
  sensitive   = true
  description = "The administrator password for the Azure SQL Server"
}

variable "firewall_rule_name" {
  type        = string
  description = "The name of the firewall rule"
}

variable "start_ip_address" {
  type        = string
  description = "The start IP address of the firewall rule"
}

variable "end_ip_address" {
  type        = string
  description = "The end IP address of the firewall rule"
}

resource "azurerm_resource_group" "example" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_mssql_server" "example" {
  name                = var.sql_server_name
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  version             = "12.0"

  administrator_login          = var.sql_admin_login
  administrator_login_password = var.sql_admin_password
}

resource "azurerm_mssql_database" "example" {
  name        = var.sql_database_name
  server_id   = azurerm_mssql_server.example.id
  sku_name    = "S0"
  max_size_gb = 10
}

resource "azurerm_mssql_firewall_rule" "example" {
  name                = var.firewall_rule_name
  server_id           = azurerm_mssql_server.example.id
  start_ip_address    = var.start_ip_address
  end_ip_address      = var.end_ip_address
}