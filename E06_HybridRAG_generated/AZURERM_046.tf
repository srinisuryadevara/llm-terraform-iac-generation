# Configure the Azure provider
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0.0"
    }
  }
  required_version = ">= 0.14.9"
}

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
  default     = "rg-terraform-dev"
}

variable "appservice_plan_id" {
  type        = string
  default     = "asp-terraform-dev"
}

variable "always_on" {
  type        = bool
  default     = true
}

variable "use_32_bit_worker" {
  type        = bool
  default     = false
}

variable "node_version" {
  type        = string
  default     = "14-lts"
}

variable "app_command_line" {
  type        = string
  default     = ""
}

variable "health_check_path" {
  type        = string
  default     = ""
}

variable "app_settings" {
  type        = map(string)
  default     = {
    "WEBSITE_NODE_DEFAULT_VERSION" = "14-lts"
  }
}

variable "identity" {
  type        = list(map(string))
  default     = []
}

variable "tags" {
  type        = map(string)
  default     = {
    "environment" = "dev"
  }
}

# Create the resource group
resource "azurerm_resource_group" "rg" {
  name     = var.rg_name
  location = var.location
}

# Create the App Service plan
resource "azurerm_service_plan" "plan" {
  name                = var.appservice_plan_id
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  os_type             = "Linux"
  sku_name            = "B1"
}

# Create the web app
resource "azurerm_linux_web_app" "web" {
  name                = "${var.service_name}-${var.resource_token}"
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