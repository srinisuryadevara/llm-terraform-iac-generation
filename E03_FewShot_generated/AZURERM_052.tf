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
  description = "Location of the resources"
}

variable "sql_server_name" {
  type        = string
  description = "Name of the SQL server"
}

variable "sql_database_name" {
  type        = string
  description = "Name of the SQL database"
}

variable "sql_server_admin_login" {
  type        = string
  sensitive   = true
  description = "SQL server admin login"
}

variable "sql_server_admin_password" {
  type        = string
  sensitive   = true
  description = "SQL server admin password"
}

variable "firewall_rule_name" {
  type        = string
  description = "Name of the firewall rule"
}

variable "firewall_rule_start_ip" {
  type        = string
  description = "Start IP address of the firewall rule"
}

variable "firewall_rule_end_ip" {
  type        = string
  description = "End IP address of the firewall rule"
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

output "sql_server_name" {
  value = azurerm_sql_server.example.name
}

output "sql_database_name" {
  value = azurerm_sql_database.example.name
}