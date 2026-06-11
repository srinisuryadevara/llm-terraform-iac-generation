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

variable "sqlserver" {}

variable "username" {}

variable "password" {}

variable "server" {}

variable "apiport" {}

variable "pgdatabase" {}

variable "sqlserverdb" {}

variable "sqluid" {}

variable "sqlpwd" {}

resource "azurerm_sql_server" "sqlserver" {
  name                         = var.sqlserver
  resource_group_name          = azurerm_resource_group.example.name
  location                     = azurerm_resource_group.example.location
  version                      = "12.0"
  administrator_login          = var.username
  administrator_login_password = var.password
}

resource "azurerm_sql_database" "example" {
  name                = var.sqlserverdb
  resource_group_name = azurerm_resource_group.example.name
  server_name         = azurerm_sql_server.sqlserver.name
  edition              = "Basic"
  collation           = "SQL_Latin1_General_CP1_CI_AS"
}

resource "azurerm_sql_firewall_rule" "example" {
  name                = "example-firewall-rule"
  resource_group_name = azurerm_resource_group.example.name
  server_name         = azurerm_sql_server.sqlserver.name
  start_ip_address    = "0.0.0.0"
  end_ip_address      = "0.0.0.0"
}

output "sqlserver_dsn" {
  value="Driver={ODBC Driver 17 for SQL Server};Server=${azurerm_sql_server.sqlserver.fully_qualified_domain_name};Database=${var.sqlserverdb};UID=${var.sqluid};PWD=${var.sqlpwd};"
}