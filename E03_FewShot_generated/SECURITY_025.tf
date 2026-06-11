provider "azurerm" {
  version = "3.34.0"
  features {}
}

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
  description = "The name of the Azure SQL Server"
}

variable "administrator_login" {
  type        = string
  sensitive   = true
  description = "The administrator login for the Azure SQL Server"
}

variable "administrator_login_password" {
  type        = string
  sensitive   = true
  description = "The administrator login password for the Azure SQL Server"
}

variable "tenant_id" {
  type        = string
  sensitive   = true
  description = "The tenant ID for Azure AD authentication"
}

variable "object_id" {
  type        = string
  sensitive   = true
  description = "The object ID for Azure AD authentication"
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
    object_id          = var.object_id
    tenant_id          = var.tenant_id
  }

  extended_auditing_policy {
    storage_endpoint                        = "https://mystorageaccount.blob.core.windows.net"
    storage_account_access_key              = "default"
    storage_account_access_key_is_secondary = true
    retention_in_days                       = 0
  }

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_mssql_server_security_alert_policy" "example" {
  resource_group_name = azurerm_resource_group.example.name
  server_name         = azurerm_mssql_server.example.name
  state               = "Enabled"
}

resource "azurerm_mssql_server_vulnerability_assessment" "example" {
  server_id                = azurerm_mssql_server.example.id
  storage_container_path   = "https://mystorageaccount.blob.core.windows.net/vulnerability-assessment/"
  storage_account_access_key = "default"
  recurring_scans {
    enabled = true
    email_subscription_admins = true
    emails = ["email@example.com"]
  }
}

resource "azurerm_mssql_server_active_directory_administrator" "example" {
  server_id         = azurerm_mssql_server.example.id
  login             = var.administrator_login
  object_id         = var.object_id
  tenant_id         = var.tenant_id
}

resource "azurerm_sql_active_directory_administrator" "example" {
  server_id         = azurerm_mssql_server.example.id
  login             = var.administrator_login
  object_id         = var.object_id
  tenant_id         = var.tenant_id
}

resource "null_resource" "disable_sql_login" {
  provisioner "local-exec" {
    command = "az sql server ad-admin update --resource-group ${azurerm_resource_group.example.name} --server ${azurerm_mssql_server.example.name} --display-name ${var.administrator_login} --object-id ${var.object_id} --tenant-id ${var.tenant_id} --sql-auth-update-disable"
  }
}