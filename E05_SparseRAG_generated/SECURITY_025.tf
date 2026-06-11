# Since many services require a globally unique name (such as sql server),
# generate random suffix for the resources
resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}

locals {
  # SQL server required globally unique names. Only alphanumeric characters allowed
  sql_server_name = "${var.name_prefix}sql-server-${random_string.suffix.result}"
}

resource "azurerm_resource_group" "current" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_sql_server" "current" {
  name                         = local.sql_server_name
  resource_group_name          = azurerm_resource_group.current.name
  location                     = azurerm_resource_group.current.location
  version                      = "12.0"
  administrator_login          = null
  administrator_login_password = null

  # Azure AD authentication
  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_mssql_server_security_alert_policy" "current" {
  resource_group_name        = azurerm_resource_group.current.name
  server_name                = azurerm_sql_server.current.name
  state                      = "Enabled"
  storage_endpoint           = var.storage_endpoint
  storage_account_access_key = var.storage_account_access_key
  disabled_alerts            = []
  email_addresses            = var.email_addresses
  retention_days             = 0
}

resource "azurerm_active_directory_administrator" "current" {
  login               = var.active_directory_login
  object_id           = var.active_directory_object_id
  resource_group_name = azurerm_resource_group.current.name
  server_name         = azurerm_sql_server.current.name
  tenant_id           = var.tenant_id
}