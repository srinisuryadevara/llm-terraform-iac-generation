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

variable "sqlserverdb" {
  type = string
}

variable "sqluid" {
  type = string
  sensitive = true
}

variable "sqlpwd" {
  type = string
  sensitive = true
}

variable "location" {
  type = string
}

variable "rgName" {
  type = string
}

resource "azurerm_resource_group" "example" {
  name = var.rgName
  location = var.location
}

resource "azurerm_sql_server" "example" {
  name = var.sqlserver
  resource_group_name = azurerm_resource_group.example.name
  location = azurerm_resource_group.example.location
  version = "12.0"
  administrator_login = var.sqluid
  administrator_login_password = var.sqlpwd
}

resource "azurerm_sql_database" "example" {
  name = var.sqlserverdb
  resource_group_name = azurerm_resource_group.example.name
  location = azurerm_resource_group.example.location
  server_name = azurerm_sql_server.example.name
  edition = "Standard"
  requested_service_objective_name = "S0"
}

output "sqlserver_dsn" {
  value = "Driver={ODBC Driver 17 for SQL Server};Server=${azurerm_sql_server.example.fully_qualified_domain_name};Database=${var.sqlserverdb};UID=${var.sqluid};PWD=${var.sqlpwd};"
}