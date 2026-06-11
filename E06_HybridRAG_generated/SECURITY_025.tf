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

resource "azurecaf_name" "sql_server_name" {
  name          = var.resource_token
  resource_type = "azurerm_mssql_server"
  random_length = 0
  clean_input   = true
}

resource "azurerm_mssql_server" "sql_server" {
  name                = azurecaf_name.sql_server_name.result
  location            = var.location
  resource_group_name = var.rg_name
  version             = "12.0"

  azure_ad_administrator {
    login              = var.sql_admin_login
    object_id          = var.sql_admin_object_id
    tenant_id          = data.azurerm_client_config.current.tenant_id
  }

  extended_auditing_policy {
    storage_endpoint                        = ""
    storage_account_access_key              = ""
    storage_account_access_key_is_secondary = true
    retention_in_days                       = 0
  }

  lifecycle {
    ignore_changes = [extended_auditing_policy]
  }
}

data "azurerm_client_config" "current" {
}

resource "azurerm_mssql_server_security_alert_policy" "sql_server_security_alert_policy" {
  resource_group_name = var.rg_name
  server_name         = azurerm_mssql_server.sql_server.name
  state               = "Enabled"
}

resource "azurerm_mssql_server_vulnerability_assessment" "sql_server_vulnerability_assessment" {
  server_id = azurerm_mssql_server.sql_server.id
  storage_container_path = "${azurerm_storage_account.sql_server_storage_account.primary_blob_endpoint}${azurerm_storage_container.sql_server_storage_container.name}/"
  storage_account_access_key = azurerm_storage_account.sql_server_storage_account.primary_access_key
  recurring_scans {
    enabled = true
    email_subscription_admins = true
    emails = []
  }
}

resource "azurerm_storage_account" "sql_server_storage_account" {
  name                     = "${var.resource_token}sqlserverstorage"
  resource_group_name      = var.rg_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_container" "sql_server_storage_container" {
  name                     = "vulnerability-assessment"
  storage_account_name  = azurerm_storage_account.sql_server_storage_account.name
  container_access_type = "private"
}