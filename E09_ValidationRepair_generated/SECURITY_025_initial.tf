provider "azurerm" {
  version = "3.34.0"
  features {}
}

variable "subscription_id" {
  type        = string
  sensitive   = true
}

variable "client_id" {
  type        = string
  sensitive   = true
}

variable "client_secret" {
  type        = string
  sensitive   = true
}

variable "tenant_id" {
  type        = string
  sensitive   = true
}

variable "resource_group_name" {
  type        = string
}

variable "location" {
  type        = string
}

variable "sql_server_name" {
  type        = string
}

variable "administrator_login" {
  type        = string
}

variable "administrator_object_id" {
  type        = string
}

provider "azuread" {
  version = "2.28.1"
  client_id     = var.client_id
  client_secret = var.client_secret
  tenant_id     = var.tenant_id
}

resource "azurerm_resource_group" "example" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_mssql_server" "example" {
  name                = var.sql_server_name
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  version             = "12.0"

  azuread_administrator {
    login              = var.administrator_login
    object_id          = var.administrator_object_id
    tenant_id          = var.tenant_id
  }

  extended_auditing_policy {
    storage_endpoint                        = "https://mystorageaccount.blob.core.windows.net"
    storage_account_access_key              = "default"
    storage_account_access_key_is_secondary = true
    retention_in_days                       = 0
  }

  tags = {
    environment = "production"
  }
}

resource "azurerm_mssql_server_security_alert_policy" "example" {
  resource_group_name = azurerm_resource_group.example.name
  server_name         = azurerm_mssql_server.example.name
  state               = "Enabled"
}

resource "azurerm_mssql_server_vulnerability_assessment" "example" {
  resource_group_name = azurerm_resource_group.example.name
  server_name         = azurerm_mssql_server.example.name
  storage_container_path = "https://mystorageaccount.blob.core.windows.net/vulnerability-assessment/"
  storage_account_access_key = "default"
  recurring_scans {
    enabled = true
    email_subscription_admins = true
    emails = ["email@example.com"]
  }
}