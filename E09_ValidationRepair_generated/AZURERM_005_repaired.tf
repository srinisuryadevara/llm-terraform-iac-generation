provider "azurerm" {
  features {}
}

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group"
}

variable "location" {
  type        = string
  description = "Location of the resource group"
}

variable "log_analytics_workspace_name" {
  type        = string
  description = "Name of the Log Analytics workspace"
}

variable "log_analytics_workspace_sku" {
  type        = string
  description = "Sku of the Log Analytics workspace"
}

variable "storage_account_id" {
  type        = string
  description = "Id of the storage account"
}

resource "azurerm_log_analytics_workspace" "example" {
  name                = var.log_analytics_workspace_name
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = var.log_analytics_workspace_sku
  tags = {
    environment = "example"
  }
}

resource "azurerm_monitor_diagnostic_setting" "example" {
  name                       = "example-diagnostic-setting"
  target_resource_id         = var.storage_account_id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.example.id
  tags = {
    environment = "example"
  }

  log {
    category = "StorageRead"
    enabled  = true

    retention_policy {
      enabled = true
      days    = 30
    }
  }

  log {
    category = "StorageWrite"
    enabled  = true

    retention_policy {
      enabled = true
      days    = 30
    }
  }

  metric {
    category = "AllMetrics"
    enabled  = true

    retention_policy {
      enabled = true
      days    = 30
    }
  }
}

output "log_analytics_workspace_id" {
  value       = azurerm_log_analytics_workspace.example.id
  description = "The ID of the Log Analytics workspace"
}

output "log_analytics_workspace_name" {
  value       = azurerm_log_analytics_workspace.example.name
  description = "The name of the Log Analytics workspace"
}

output "diagnostic_setting_id" {
  value       = azurerm_monitor_diagnostic_setting.example.id
  description = "The ID of the diagnostic setting"
}

output "diagnostic_setting_name" {
  value       = azurerm_monitor_diagnostic_setting.example.name
  description = "The name of the diagnostic setting"
}