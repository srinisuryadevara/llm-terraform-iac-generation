terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "2.41.0"
    }
  }
}

provider "azurerm" {
  features {}
}

variable "sqlserver" {
  type = string
}

variable "username" {
  type = string
  sensitive = true
}

variable "password" {
  type = string
  sensitive = true
}

variable "location" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "sql_database_name" {
  type = string
}

variable "sql_database_edition" {
  type = string
}

variable "sql_database_service_objective_name" {
  type = string
}

resource "azurerm_resource_group" "example" {
  name = var.resource_group_name
  location = var.location
}

resource "azurerm_sql_server" "example" {
  name = var.sqlserver
  resource_group_name = azurerm_resource_group.example.name
  location = azurerm_resource_group.example.location
  version = "12.0"
  administrator_login = var.username
  administrator_login_password = var.password
}

resource "azurerm_sql_database" "example" {
  name = var.sql_database_name
  resource_group_name = azurerm_resource_group.example.name
  location = azurerm_resource_group.example.location
  server_name = azurerm_sql_server.example.name
  edition = var.sql_database_edition
  requested_service_objective_name = var.sql_database_service_objective_name
}

output "sql_server_name" {
  value = azurerm_sql_server.example.name
}

output "sql_database_name" {
  value = azurerm_sql_database.example.name
}