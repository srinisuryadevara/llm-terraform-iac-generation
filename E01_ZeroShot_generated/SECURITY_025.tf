provider "azurerm" {
  features {}
}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "sql_server_name" {
  type = string
}

variable "administrator_login" {
  type = string
}

variable "tenant_id" {
  type = string
}

variable "object_id" {
  type = string
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
    object_id           = var.object_id
    tenant_id           = var.tenant_id
  }

  extended_auditing_policy {
    storage_endpoint                        = "https://mystorageaccount.blob.core.windows.net"
    storage_account_access_key                = "default"
    storage_account_access_key_is_secondary  = true
    retention_in_days                       = 0
  }

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_mssql_server_security_alert_policy" "example" {
  resource_group_name = azurerm_resource_group.example.name
  server_name         = azurerm_mssql_server.example.name

  state                      = "Enabled"
  email_addresses            = []
  email_account_admins       = "Disabled"
  retention_days             = 0
}

resource "azurerm_mssql_server_vulnerability_assessment" "example" {
  server_id = azurerm_mssql_server.example.id
}

resource "azurerm_mssql_server_transparent_data_encryption" "example" {
  server_id = azurerm_mssql_server.example.id
}

resource "azurerm_sql_active_directory_administrator" "example" {
  server_id = azurerm_mssql_server.example.id
  login     = var.administrator_login
  object_id = var.object_id
  tenant_id = var.tenant_id
}

resource "azurerm_mssql_server_azuread_administrator" "example" {
  server_id = azurerm_mssql_server.example.id
  login     = var.administrator_login
  object_id = var.object_id
  tenant_id = var.tenant_id
}

resource "null_resource" "disable_sql_login" {
  provisioner "local-exec" {
    command = "az sql server update --resource-group ${azurerm_resource_group.example.name} --name ${azurerm_mssql_server.example.name} --disable-public-network-access --admin-password-disabled"
  }
}