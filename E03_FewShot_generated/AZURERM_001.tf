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
  description = "The name of the SQL server"
}

variable "sql_database_name" {
  type        = string
  description = "The name of the SQL database"
}

variable "sql_admin_login" {
  type        = string
  sensitive   = true
  description = "The administrator login for the SQL server"
}

variable "sql_admin_password" {
  type        = string
  sensitive   = true
  description = "The administrator password for the SQL server"
}

variable "firewall_rule_name" {
  type        = string
  description = "The name of the firewall rule"
}

variable "firewall_rule_start_ip" {
  type        = string
  description = "The start IP address of the firewall rule"
}

variable "firewall_rule_end_ip" {
  type        = string
  description = "The end IP address of the firewall rule"
}

resource "azurerm_resource_group" "example" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_sql_server" "example" {
  name                = var.sql_server_name
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  version             = "12.0"

  administrator_login          = var.sql_admin_login
  administrator_login_password = var.sql_admin_password
}

resource "azurerm_sql_database" "example" {
  name                = var.sql_database_name
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  server_name         = azurerm_sql_server.example.name
  edition             = "Basic"
}

resource "azurerm_sql_firewall_rule" "example" {
  name                = var.firewall_rule_name
  resource_group_name = azurerm_resource_group.example.name
  server_name         = azurerm_sql_server.example.name
  start_ip_address    = var.firewall_rule_start_ip
  end_ip_address      = var.firewall_rule_end_ip
}