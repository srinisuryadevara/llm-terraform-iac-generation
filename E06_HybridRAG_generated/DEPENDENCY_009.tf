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

resource "azurerm_resource_group" "example" {
  name = "example-rg"
  location = "westus2"
}

variable "sqlserver" {
  type = string
}

variable "username" {
  type = string
}

variable "password" {
  type = string
  sensitive = true
}

variable "server" {
  type = string
}

variable "database" {
  type = string
}

variable "sqluid" {
  type = string
}

variable "sqlpwd" {
  type = string
  sensitive = true
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
  name = var.database
  resource_group_name = azurerm_resource_group.example.name
  server_name = azurerm_sql_server.example.name
  edition = "Basic"
  collation = "SQL_Latin1_General_CP1_CI_AS"
  sku_name = "S0"
}

output "sqlserver_name" {
  value = azurerm_sql_server.example.name
}

output "sqlserver_fqdn" {
  value = azurerm_sql_server.example.fully_qualified_domain_name
}

output "sql_database_name" {
  value = azurerm_sql_database.example.name
}