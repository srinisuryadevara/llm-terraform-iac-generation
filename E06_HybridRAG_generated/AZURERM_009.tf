terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "3.34.0"
    }
  }
}

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

variable "sql_server_admin_username" {
  type = string
  sensitive = true
}

variable "sql_server_admin_password" {
  type = string
  sensitive = true
}

variable "firewall_rule_name" {
  type = string
}

variable "start_ip_address" {
  type = string
}

variable "end_ip_address" {
  type = string
}

resource "azurerm_resource_group" "example" {
  name = var.resource_group_name
  location = var.location
}

resource "azurerm_sql_server" "example" {
  name                         = var.sql_server_name
  resource_group_name          = azurerm_resource_group.example.name
  location                     = azurerm_resource_group.example.location
  version                      = "12.0"
  administrator_login          = var.sql_server_admin_username
  administrator_login_password = var.sql_server_admin_password
}

resource "azurerm_sql_database" "example" {
  name                = var.sql_database_name
  resource_group_name = azurerm_resource_group.example.name
  server_name         = azurerm_sql_server.example.name
  edition              = "Basic"
}

resource "azurerm_sql_firewall_rule" "example" {
  name                = var.firewall_rule_name
  resource_group_name = azurerm_resource_group.example.name
  server_name         = azurerm_sql_server.example.name
  start_ip_address    = var.start_ip_address
  end_ip_address      = var.end_ip_address
}

output "sql_server_name" {
  value = azurerm_sql_server.example.name
}

output "sql_database_name" {
  value = azurerm_sql_database.example.name
}

output "sql_server_fqdn" {
  value = azurerm_sql_server.example.fully_qualified_domain_name
}