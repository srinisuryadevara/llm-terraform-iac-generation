# Configure the Azure provider
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0.0"
    }
    azurecaf = {
      source  = "aztfmod/azurecaf"
      version = "~>1.2.24"
    }
  }
  required_version = ">= 0.14.9"
}

# Provider configuration
provider "azurerm" {
  features {}
}

# Variables
variable "service_name" {
  type        = string
  default     = "example"
}

variable "resource_token" {
  type        = string
  default     = "dev"
}

variable "location" {
  type        = string
  default     = "eastus"
}

variable "rg_name" {
  type        = string
  default     = "example-rg"
}

variable "appservice_plan_id" {
  type        = string
  default     = "example-plan"
}

variable "tags" {
  type        = map(string)
  default     = {
    environment = "dev"
  }
}

variable "always_on" {
  type        = bool
  default     = true
}

variable "use_32_bit_worker" {
  type        = bool
  default     = false
}

variable "app_command_line" {
  type        = string
  default     = ""
}

variable "node_version" {
  type        = string
  default     = "14-lts"
}

variable "health_check_path" {
  type        = string
  default     = ""
}

variable "app_settings" {
  type        = map(string)
  default     = {
    WEBSITE_NODE_DEFAULT_VERSION = "14-lts"
  }
}

variable "identity" {
  type        = list(map(string))
  default     = []
}

# Resource group
resource "azurerm_resource_group" "rg" {
  name     = var.rg_name
  location = var.location
}

# App service plan name
resource "azurecaf_name" "plan_name" {
  name          = var.appservice_plan_id
  resource_type = "azurerm_app_service_plan"
  random_length = 0
  clean_input   = true
}

# App service plan
resource "azurerm_service_plan" "plan" {
  name                = azurecaf_name.plan_name.result
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  os_type             = "Linux"
  sku_name            = "B1"
}

# Web app name
resource "azurecaf_name" "web_name" {
  name          = "${var.service_name}-${var.resource_token}"
  resource_type = "azurerm_app_service"
  random_length = 0
  clean_input   = true
}

# Web app
resource "azurerm_linux_web_app" "web" {
  name                = azurecaf_name.web_name.result
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  service_plan_id     = azurerm_service_plan.plan.id
  https_only          = true
  tags                = var.tags

  site_config {
    always_on         = var.always_on
    use_32_bit_worker = var.use_32_bit_worker
    ftps_state        = "FtpsOnly"
    app_command_line  = var.app_command_line
    application_stack {
      node_version = var.node_version
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

  logs {
    application_logs {
      file_system_level = "Verbose"
    }
  }
}