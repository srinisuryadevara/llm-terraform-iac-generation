provider "azurerm" {
  version = "3.34.0"
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

variable "sql_admin_username" {
  type      = string
  sensitive = true
}

variable "sql_admin_password" {
  type      = string
  sensitive = true
}

variable "environment" {
  type = string
  default = "dev"
}

resource "azurerm_resource_group" "example" {
  name     = var.resource_group_name
  location = var.location
  tags = {
    Environment = var.environment
  }
}

resource "azurerm_sql_server" "example" {
  name                = var.sql_server_name
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  version             = "12.0"

  administrator_login          = var.sql_admin_username
  administrator_login_password = var.sql_admin_password
  tags = {
    Environment = var.environment
  }
}

resource "azurerm_sql_database" "example" {
  name                = var.sql_database_name
  resource_group_name = azurerm_resource_group.example.name
  server_name         = azurerm_sql_server.example.name
  edition             = "Basic"
  tags = {
    Environment = var.environment
  }
}

output "resource_group_id" {
  value = azurerm_resource_group.example.id
}

output "sql_server_id" {
  value = azurerm_sql_server.example.id
}

output "sql_database_id" {
  value = azurerm_sql_database.example.id
}

output "sql_server_name" {
  value = azurerm_sql_server.example.name
}

output "sql_database_name" {
  value = azurerm_sql_database.example.name
}