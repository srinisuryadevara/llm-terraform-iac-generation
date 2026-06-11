provider "azurerm" {
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

provider "azurerm" {
  alias                   = "primary"
  subscription_id         = var.subscription_id
  client_id               = var.client_id
  client_secret           = var.client_secret
  tenant_id               = var.tenant_id
  features {}
}

resource "azurerm_resource_group" "example" {
  provider = azurerm.primary
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_mssql_server" "example" {
  provider = azurerm.primary
  name                = var.sql_server_name
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  version             = "12.0"

  azuread_administrator {
    login              = var.administrator_login
    object_id           = var.administrator_object_id
    tenant_id           = var.tenant_id
  }

  extended_auditing_policy {
    storage_endpoint                        = ""
    storage_account_access_key              = ""
    storage_account_access_key_is_secondary = false
    retention_in_days                       = 0
  }
}

resource "azurerm_mssql_server_security_alert_policy" "example" {
  provider = azurerm.primary
  resource_group_name = azurerm_resource_group.example.name
  server_name         = azurerm_mssql_server.example.name
  state               = "Enabled"
}

resource "azurerm_mssql_server_vulnerability_assessment" "example" {
  provider = azurerm.primary
  server_id = azurerm_mssql_server.example.id
  storage_container_path = ""
  storage_account_access_key = ""
  recurring_scans {
    enabled = true
    email_subscription_admins = true
    emails = []
  }
}