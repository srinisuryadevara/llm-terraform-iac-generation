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

variable "diagsettings_enabled" {
  type = bool
}

variable "diagsettings_logs_category" {
  type = map(string)
}

variable "diagsettings_metric_category" {
  type = map(string)
}

variable "diagsettings_retention_days" {
  type = number
}

variable "environment" {
  type = string
}

variable "log_analytics_workspace" {
  type = map(string)
}

variable "log_analytics_workspace_rg_name" {
  type = string
}

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

resource "azurecaf_name" "workspace_name" {
  name          = var.resource_token
  resource_type = "azurerm_log_analytics_workspace"
  random_length = 0
  clean_input   = true
}

resource "azurerm_log_analytics_workspace" "workspace" {
  name                = azurecaf_name.workspace_name.result
  location            = var.location
  resource_group_name = var.rg_name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = var.tags
}

resource "azurerm_monitor_diagnostic_setting" "diasettings" {
  count                      = var.diagsettings_enabled ? 1 : 0
  name                       = "log-analytics-diagnostic-setting"
  target_resource_id         = azurerm_log_analytics_workspace.workspace.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.workspace.id

  dynamic "log" {
    for_each = var.diagsettings_logs_category
    content {
      category = log.key
      enabled  = log.value

      retention_policy {
        days    = log.value ? var.diagsettings_retention_days : 0
        enabled = log.value
      }
    }
  }

  dynamic "metric" {
    for_each = var.diagsettings_metric_category
    content {
      category = metric.key
      enabled  = metric.value

      retention_policy {
        days    = metric.value ? var.diagsettings_retention_days : 0
        enabled = metric.value
      }
    }
  }
}