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
  description = "The name of the Azure SQL server"
}

variable "sql_database_name" {
  type        = string
  description = "The name of the Azure SQL database"
}

variable "sql_admin_login" {
  type        = string
  sensitive   = true
  description = "The administrator login for the Azure SQL server"
}

variable "sql_admin_password" {
  type        = string
  sensitive   = true
  description = "The administrator password for the Azure SQL server"
}

variable "sql_database_edition" {
  type        = string
  default     = "Standard"
  description = "The edition of the Azure SQL database"
}

variable "sql_database_requested_service_objective_name" {
  type        = string
  default     = "S0"
  description = "The service objective name for the Azure SQL database"
}

provider "azurerm" {
  features {}
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
  edition             = var.sql_database_edition

  extended_auditing_policy {
    storage_endpoint                        = "https://mystorageaccount.blob.core.windows.net"
    storage_account_access_key              = "default"
    storage_account_access_key_is_secondary = true
    retention_in_days                       = 0
  }

  short_term_retention_policy {
    retention_days = 35
  }

  sku_name = var.sql_database_requested_service_objective_name
}