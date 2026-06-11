terraform {
  required_version = ">= 1.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.0, < 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

variable "location" {
  type = string
}

variable "environment_name" {
  type = string
}

variable "cosmosdb_account_name" {
  type    = string
  default = null
}

variable "cosmosdb_account_location" {
  type = string
}

variable "cosmosdb_sqldb_name" {
  type = string
}

variable "cosmosdb_container_name" {
  type = string
}

variable "cosmosdb_container_partition_key_path" {
  type = string
}

variable "sqlserver" {
  type = string
}

variable "username" {
  type = string
}

variable "password" {
  type = string
}

variable "server" {
  type = string
}

variable "apiport" {
  type = number
}

variable "pgdatabase" {
  type = string
}

variable "sqlserverdb" {
  type = string
}

variable "sqluid" {
  type = string
}

variable "sqlpwd" {
  type = string
}

resource "azurerm_resource_group" "example" {
  name     = "${random_pet.prefix.id}-rg"
  location = var.location
}

resource "random_pet" "prefix" {
  length = 5
}

resource "random_string" "db_account_name" {
  count = var.cosmosdb_account_name == null ? 1 : 0

  length  = 20
  upper   = false
  special = false
  numeric = false
}

locals {
  cosmosdb_account_name = try(random_string.db_account_name[0].result, var.cosmosdb_account_name)
}

resource "azurerm_cosmosdb_account" "example" {
  name                      = local.cosmosdb_account_name
  location                  = var.cosmosdb_account_location
  resource_group_name       = azurerm_resource_group.example.name
  offer_type                = "Standard"
  kind                      = "GlobalDocumentDB"
  enable_automatic_failover = false
  geo_location {
    location          = var.location
    failover_priority = 0
  }
  consistency_policy {
    consistency_level       = "BoundedStaleness"
    max_interval_in_seconds = 300
    max_staleness_prefix    = 100000
  }
  depends_on = [
    azurerm_resource_group.example
  ]
}

resource "azurerm_cosmosdb_sql_database" "main" {
  name                = var.cosmosdb_sqldb_name
  resource_group_name = azurerm_resource_group.example.name
  account_name        = azurerm_cosmosdb_account.example.name
}

resource "azurerm_cosmosdb_sql_container" "main" {
  name                  = var.cosmosdb_container_name
  resource_group_name   = azurerm_resource_group.example.name
  account_name          = azurerm_cosmosdb_account.example.name
  database_name         = azurerm_cosmosdb_sql_database.main.name
  partition_key_path    = var.cosmosdb_container_partition_key_path
  partition_key_version = 1
  throughput            = 400
}

resource "azurerm_sql_server" "sqlserver" {
  name                = var.sqlserver
  resource_group_name = azurerm_resource_group.example.name
  location            = var.location
  version             = "12.0"
  administrator_login = var.username
  administrator_login_password = var.password
}

resource "azurerm_sql_database" "sqldb" {
  name                = var.sqlserverdb
  resource_group_name = azurerm_resource_group.example.name
  location            = var.location
  server_name         = azurerm_sql_server.sqlserver.name
  edition             = "Basic"
}

output "cosmosdb_account_name" {
  value = azurerm_cosmosdb_account.example.name
}

output "cosmosdb_account_key" {
  value     = azurerm_cosmosdb_account.example.primary_key
  sensitive = true
}

output "sqlserver_dsn" {
  value = "Driver={ODBC Driver 17 for SQL Server};Server=${azurerm_sql_server.sqlserver.fully_qualified_domain_name};Database=${var.sqlserverdb};UID=${var.sqluid};PWD=${var.sqlpwd};"
}