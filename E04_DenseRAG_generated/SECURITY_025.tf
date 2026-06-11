terraform {
  required_providers {
    azurerm = {
      version = "~>3.47.0"
      source  = "hashicorp/azurerm"
    }
    azurecaf = {
      source  = "aztfmod/azurecaf"
      version = "~>1.2.24"
    }
  }
}

variable "resource_token" {
  type = string
}

variable "location" {
  type = string
}

variable "rg_name" {
  type = string
}

variable "tags" {
  type = map(string)
}

variable "sql_admin_login" {
  type = string
}

variable "sql_admin_object_id" {
  type = string
}

data "azurerm_client_config" "current" {}

resource "azurecaf_name" "sql_server_name" {
  name          = var.resource_token
  resource_type = "azurerm_sql_server"
  random_length = 0
  clean_input   = true
}

resource "azurerm_sql_server" "sql_server" {
  name                         = azurecaf_name.sql_server_name.result
  location                     = var.location
  resource_group_name          = var.rg_name
  version                      = "12.0"
  administrator_login          = var.sql_admin_login
  administrator_login_password = null
  extended_auditing_policy {
    storage_endpoint                        = null
    storage_account_access_key              = null
    storage_account_access_key_is_secondary = false
    retention_in_days                       = 0
  }
  azuread_administrator {
    login              = var.sql_admin_login
    object_id          = var.sql_admin_object_id
    tenant_id          = data.azurerm_client_config.current.tenant_id
  }
  tags = var.tags
}

resource "azurerm_mssql_server_security_alert_policy" "sql_server_security_alert_policy" {
  resource_group_name = var.rg_name
  server_name         = azurerm_sql_server.sql_server.name
  state               = "Enabled"
}

resource "azurerm_mssql_server_vulnerability_assessment" "sql_server_vulnerability_assessment" {
  resource_group_name = var.rg_name
  server_name         = azurerm_sql_server.sql_server.name
  storage_container_path = null
  storage_account_access_key = null
  recurring_scans {
    enabled = true
    email_subscription_admins = true
    emails = []
  }
}

output "sql_server_name" {
  value = azurerm_sql_server.sql_server.name
}

output "sql_server_fqdn" {
  value = azurerm_sql_server.sql_server.fully_qualified_domain_name
}