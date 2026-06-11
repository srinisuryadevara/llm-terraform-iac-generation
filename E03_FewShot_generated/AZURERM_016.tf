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

variable "log_analytics_workspace_name" {
  type        = string
  description = "The name of the Log Analytics workspace"
}

variable "log_analytics_workspace_sku" {
  type        = string
  description = "The SKU of the Log Analytics workspace"
}

variable "storage_account_id" {
  type        = string
  description = "The ID of the storage account"
}

variable "eventhub_id" {
  type        = string
  description = "The ID of the event hub"
}

resource "azurerm_log_analytics_workspace" "example" {
  name                = var.log_analytics_workspace_name
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = var.log_analytics_workspace_sku
}

resource "azurerm_monitor_diagnostic_setting" "example" {
  name                       = "example-diagnostic-setting"
  target_resource_id         = azurerm_log_analytics_workspace.example.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.example.id

  log {
    category = "Audit"
    enabled  = true

    metric {
      category = "AllMetrics"
      enabled  = true
    }
  }

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}

resource "azurerm_monitor_diagnostic_setting" "storage_account" {
  name                       = "storage-account-diagnostic-setting"
  target_resource_id         = var.storage_account_id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.example.id

  log {
    category = "StorageRead"
    enabled  = true

    metric {
      category = "Transaction"
      enabled  = true
    }
  }

  metric {
    category = "Transaction"
    enabled  = true
  }
}

resource "azurerm_monitor_diagnostic_setting" "eventhub" {
  name                       = "eventhub-diagnostic-setting"
  target_resource_id         = var.eventhub_id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.example.id

  log {
    category = "Archive"
    enabled  = true

    metric {
      category = "IncomingMessages"
      enabled  = true
    }
  }

  metric {
    category = "IncomingMessages"
    enabled  = true
  }
}