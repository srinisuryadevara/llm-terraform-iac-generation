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

variable "os_type" {
  type = string
}

variable "sku_name" {
  type = string
}

variable "tags" {
  type = map(string)
}

variable "service_name" {
  type = string
}

variable "appservice_plan_id" {
  type = string
}

variable "always_on" {
  type = bool
}

variable "use_32_bit_worker" {
  type = bool
}

variable "app_command_line" {
  type = string
}

variable "python_version" {
  type = string
}

variable "health_check_path" {
  type = string
}

variable "app_settings" {
  type = map(string)
}

variable "identity" {
  type = list(object({
    type = string
  }))
}

resource "azurecaf_name" "plan_name" {
  name          = var.resource_token
  resource_type = "azurerm_app_service_plan"
  random_length = 0
  clean_input   = true
}

resource "azurerm_service_plan" "plan" {
  name                = azurecaf_name.plan_name.result
  location            = var.location
  resource_group_name = var.rg_name
  os_type             = var.os_type
  sku_name            = var.sku_name

  tags = var.tags
}

resource "azurecaf_name" "web_name" {
  name          = "${var.service_name}-${var.resource_token}"
  resource_type = "azurerm_app_service"
  random_length = 0
  clean_input   = true
}

resource "azurerm_linux_web_app" "web" {
  name                = azurecaf_name.web_name.result
  location            = var.location
  resource_group_name = var.rg_name
  service_plan_id     = azurerm_service_plan.plan.id
  https_only          = true
  tags                = var.tags

  site_config {
    always_on         = var.always_on
    use_32_bit_worker = var.use_32_bit_worker
    ftps_state        = "FtpsOnly"
    app_command_line  = var.app_command_line
    application_stack {
      python_version = var.python_version
    }
    health_check_path = var.health_check_path
  }

  app_settings = var.app_settings

  dynamic "identity" {
    for_each = { for k, v in var.identity : k => v if var.identity != [] }
    content {
      type = identity.value["type"]
    }
  }
}