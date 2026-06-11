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
  description = "The name of the log analytics workspace"
}

variable "log_analytics_workspace_sku" {
  type        = string
  description = "The sku of the log analytics workspace"
}

variable "storage_account_id" {
  type        = string
  description = "The id of the storage account"
}

variable "storage_account_name" {
  type        = string
  description = "The name of the storage account"
}

variable "diagnostic_setting_name" {
  type        = string
  description = "The name of the diagnostic setting"
}

resource "azurerm_resource_group" "example" {
  name     = var.resource_group_name
  location = var.location
  tags = {
    environment = "example"
    managed_by  = "Terraform"
  }
}

resource "azurerm_storage_account" "example" {
  name                     = var.storage_account_name
  resource_group_name      = azurerm_resource_group.example.name
  location                 = azurerm_resource_group.example.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  tags = {
    environment = "example"
    managed_by  = "Terraform"
  }
}

resource "azurerm_log_analytics_workspace" "example" {
  name                = var.log_analytics_workspace_name
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  sku                 = var.log_analytics_workspace_sku
  tags = {
    environment = "example"
    managed_by  = "Terraform"
  }
}

resource "azurerm_monitor_diagnostic_setting" "example" {
  name                       = var.diagnostic_setting_name
  target_resource_id         = azurerm_storage_account.example.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.example.id

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

output "resource_group_id" {
  value = azurerm_resource_group.example.id
}

output "storage_account_id" {
  value = azurerm_storage_account.example.id
}

output "log_analytics_workspace_id" {
  value = azurerm_log_analytics_workspace.example.id
}

output "diagnostic_setting_id" {
  value = azurerm_monitor_diagnostic_setting.example.id
}