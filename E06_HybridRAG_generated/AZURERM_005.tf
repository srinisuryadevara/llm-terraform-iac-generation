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
  type        = string
  sensitive   = true
}

variable "location" {
  type        = string
  sensitive   = false
}

variable "rg_name" {
  type        = string
  sensitive   = false
}

variable "tags" {
  type        = map(string)
  sensitive   = false
}

variable "diagsettings_enabled" {
  type        = bool
  sensitive   = false
}

variable "diagsettings_logs_category" {
  type        = map(string)
  sensitive   = false
}

variable "diagsettings_metric_category" {
  type        = map(string)
  sensitive   = false
}

variable "diagsettings_retention_days" {
  type        = number
  sensitive   = false
}

variable "log_analytics_workspace" {
  type = object({
    workspace_name = string
    workspace_rg_name = string
  })
  sensitive = false
}

variable "environment" {
  type        = string
  sensitive   = false
}

variable "acr_name" {
  type        = string
  sensitive   = false
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

data "azurerm_log_analytics_workspace" "workspace" {
  count               = var.diagsettings_enabled ? 1 : 0
  name                = azurecaf_name.workspace_name.result
  resource_group_name = var.rg_name
}

resource "azurerm_container_registry" "acr" {
  name                = var.acr_name
  resource_group_name = var.rg_name
  location            = var.location
  sku                 = "Basic"
}

resource "azurerm_monitor_diagnostic_setting" "diasettings" {
  count                      = var.diagsettings_enabled && data.azurerm_log_analytics_workspace.workspace != null ? 1 : 0
  name                       = var.acr_name
  target_resource_id         = azurerm_container_registry.acr.id
  log_analytics_workspace_id = data.azurerm_log_analytics_workspace.workspace[0].id

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