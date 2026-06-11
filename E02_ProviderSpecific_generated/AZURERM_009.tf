provider "azurerm" {
  features {}
}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "sql_server_name" {
  type = string
}

variable "sql_database_name" {
  type = string
}

variable "sql_server_admin_login" {
  type      = string
  sensitive = true
}

variable "sql_server_admin_password" {
  type      = string
  sensitive = true
}

variable "sql_server_firewall_rule_name" {
  type = string
}

variable "sql_server_firewall_rule_start_ip" {
  type = string
}

variable "sql_server_firewall_rule_end_ip" {
  type = string
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

  administrator_login          = var.sql_server_admin_login
  administrator_login_password = var.sql_server_admin_password
}

resource "azurerm_sql_database" "example" {
  name                = var.sql_database_name
  resource_group_name = azurerm_resource_group.example.name
  server_name         = azurerm_sql_server.example.name
  edition             = "Basic"
}

resource "azurerm_sql_firewall_rule" "example" {
  name                = var.sql_server_firewall_rule_name
  resource_group_name = azurerm_resource_group.example.name
  server_name         = azurerm_sql_server.example.name
  start_ip_address    = var.sql_server_firewall_rule_start_ip
  end_ip_address      = var.sql_server_firewall_rule_end_ip
}