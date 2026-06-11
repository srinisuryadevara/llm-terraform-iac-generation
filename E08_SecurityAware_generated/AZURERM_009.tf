provider "azurerm" {
  version = "3.34.0"
  features {}
}

variable "region" {
  type        = string
  description = "Azure region"
}

variable "project" {
  type        = string
  description = "Project name"
}

variable "environment" {
  type        = string
  description = "Environment name"
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

variable "sql_database_name" {
  type        = string
  description = "SQL database name"
}

variable "allowed_cidr" {
  type        = string
  description = "Allowed CIDR for firewall rules"
}

resource "azurerm_resource_group" "example" {
  name     = "${var.project}-${var.environment}-rg"
  location = var.region
  tags = {
    environment = var.environment
    project     = var.project
  }
}

resource "azurerm_sql_server" "example" {
  name                = "${var.project}-${var.environment}-sql"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  version             = "12.0"

  administrator_login          = var.sql_server_admin_login
  administrator_login_password = var.sql_server_admin_password

  extended_auditing_policy {
    storage_endpoint                        = "https://mystorageaccount.blob.core.windows.net"
    storage_account_access_key              = var.sql_server_admin_password
    storage_account_access_key_is_secondary = true
    retention_in_days                       = 0
  }

  tags = {
    environment = var.environment
    project     = var.project
  }
}

resource "azurerm_sql_database" "example" {
  name                = var.sql_database_name
  resource_group_name = azurerm_resource_group.example.name
  server_name         = azurerm_sql_server.example.name
  edition             = "Standard"

  short_term_retention_policy {
    retention_days = 35
  }

  tags = {
    environment = var.environment
    project     = var.project
  }
}

resource "azurerm_sql_firewall_rule" "example" {
  name                = "${var.project}-${var.environment}-fw-rule"
  resource_group_name = azurerm_resource_group.example.name
  server_name         = azurerm_sql_server.example.name
  start_ip_address    = var.allowed_cidr
  end_ip_address      = var.allowed_cidr
}

resource "azurerm_storage_account" "example" {
  name                     = "${var.project}${var.environment}sa"
  resource_group_name      = azurerm_resource_group.example.name
  location                 = azurerm_resource_group.example.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"

  min_tls_version = "TLS1_2"

  tags = {
    environment = var.environment
    project     = var.project
  }
}

resource "azurerm_storage_container" "example" {
  name                  = "${var.project}-${var.environment}-container"
  storage_account_name  = azurerm_storage_account.example.name
  container_access_type = "private"

  tags = {
    environment = var.environment
    project     = var.project
  }
}