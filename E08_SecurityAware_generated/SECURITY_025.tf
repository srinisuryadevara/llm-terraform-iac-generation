provider "azurerm" {
  version = "3.34.0"
  features {}
}

variable "project" {
  type        = string
  description = "Project name"
}

variable "environment" {
  type        = string
  description = "Environment name"
}

variable "location" {
  type        = string
  description = "Location"
}

variable "sql_admin_login" {
  type        = string
  sensitive   = true
  description = "SQL admin login"
}

variable "sql_admin_password" {
  type        = string
  sensitive   = true
  description = "SQL admin password"
}

variable "sql_server_name" {
  type        = string
  description = "SQL server name"
}

variable "resource_group_name" {
  type        = string
  description = "Resource group name"
}

variable "storage_account_name" {
  type        = string
  description = "Storage account name"
}

variable "key_vault_name" {
  type        = string
  description = "Key vault name"
}

variable "tenant_id" {
  type        = string
  sensitive   = true
  description = "Tenant ID"
}

variable "client_id" {
  type        = string
  sensitive   = true
  description = "Client ID"
}

variable "client_secret" {
  type        = string
  sensitive   = true
  description = "Client secret"
}

resource "azurerm_resource_group" "example" {
  name     = var.resource_group_name
  location = var.location
  tags = {
    project     = var.project
    environment = var.environment
  }
}

resource "azurerm_storage_account" "example" {
  name                     = var.storage_account_name
  resource_group_name      = azurerm_resource_group.example.name
  location                 = azurerm_resource_group.example.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"
  min_tls_version          = "TLS1_2"
  enable_https_traffic_only = true
  tags = {
    project     = var.project
    environment = var.environment
  }
}

resource "azurerm_key_vault" "example" {
  name                        = var.key_vault_name
  location                    = azurerm_resource_group.example.location
  resource_group_name         = azurerm_resource_group.example.name
  tenant_id                   = var.tenant_id
  sku_name                    = "standard"
  enabled_for_disk_encryption = true
  tags = {
    project     = var.project
    environment = var.environment
  }
}

resource "azurerm_mssql_server" "example" {
  name                = var.sql_server_name
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  version             = "12.0"
  administrator_login          = var.sql_admin_login
  administrator_login_password = var.sql_admin_password
  extended_auditing_policy {
    storage_endpoint                        = azurerm_storage_account.example.primary_blob_endpoint
    storage_account_access_key              = azurerm_storage_account.example.primary_access_key
    storage_account_access_key_is_secondary = false
    retention_in_days                       = 0
  }
  azuread_administrator {
    login              = "azureadadmin"
    object_id          = var.client_id
    tenant_id          = var.tenant_id
  }
  tags = {
    project     = var.project
    environment = var.environment
  }
}

resource "azurerm_mssql_server_security_alert_policy" "example" {
  resource_group_name = azurerm_resource_group.example.name
  server_name         = azurerm_mssql_server.example.name
  state               = "Enabled"
  storage_endpoint                  = azurerm_storage_account.example.primary_blob_endpoint
  storage_account_access_key        = azurerm_storage_account.example.primary_access_key
  storage_account_access_key_is_secondary = false
  retention_in_days                  = 0
  email_addresses                    = []
  email_account_admins              = false
}

resource "azurerm_mssql_server_transparent_data_encryption" "example" {
  resource_group_name = azurerm_resource_group.example.name
  server_name         = azurerm_mssql_server.example.name
  enabled             = true
}

resource "azurerm_mssql_server_vulnerability_assessment" "example" {
  resource_group_name = azurerm_resource_group.example.name
  server_name         = azurerm_mssql_server.example.name
  storage_container_path = "${azurerm_storage_account.example.primary_blob_endpoint}${azurerm_storage_container.example.name}/"
  storage_account_access_key = azurerm_storage_account.example.primary_access_key
  recurring_scans {
    enabled                   = true
    email_subscription_admins = false
    emails = []
  }
}

resource "azurerm_storage_container" "example" {
  name                  = "vulnerability-assessment"
  storage_account_name  = azurerm_storage_account.example.name
  container_access_type = "private"
}