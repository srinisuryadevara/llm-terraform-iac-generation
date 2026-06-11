provider "azurerm" {
  version = "3.34.0"
  features {}
}

variable "region" {
  type        = string
  description = "Azure region"
}

variable "project" {
  type        = string
  description = "Project name"
}

variable "environment" {
  type        = string
  description = "Environment name"
}

variable "storage_account_name" {
  type        = string
  description = "Storage account name"
}

variable "function_app_name" {
  type        = string
  description = "Function app name"
}

variable "consumption_plan_name" {
  type        = string
  description = "Consumption plan name"
}

variable "ssh_source_cidr" {
  type        = string
  description = "SSH source CIDR"
}

resource "azurerm_resource_group" "example" {
  name     = "${var.project}-${var.environment}-rg"
  location = var.region
  tags = {
    environment = var.environment
    project     = var.project
  }
}

resource "azurerm_storage_account" "example" {
  name                     = var.storage_account_name
  resource_group_name      = azurerm_resource_group.example.name
  location                 = azurerm_resource_group.example.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"
  min_tls_version          = "TLS1_2"
  enable_https_traffic_only = true
  tags = {
    environment = var.environment
    project     = var.project
  }
}

resource "azurerm_storage_container" "example" {
  name                  = "example-container"
  storage_account_name  = azurerm_storage_account.example.name
  container_access_type = "private"
  tags = {
    environment = var.environment
    project     = var.project
  }
}

resource "azurerm_function_app" "example" {
  name                       = var.function_app_name
  resource_group_name        = azurerm_resource_group.example.name
  location                   = azurerm_resource_group.example.location
  account_storage_name       = azurerm_storage_account.example.name
  account_container_name     = azurerm_storage_container.example.name
  os_type                    = "linux"
  version                    = "~4"
  https_only                 = true
  min_tls_version            = "1.2"
  site_config {
    linux_fx_version = "DOCKER|mcr.microsoft.com/azure-app-service/samples/node:12-lts"
  }
  app_settings = {
    WEBSITE_NODE_DEFAULT_VERSION = "10.15.2"
  }
  tags = {
    environment = var.environment
    project     = var.project
  }
}

resource "azurerm_app_service_plan" "example" {
  name                = var.consumption_plan_name
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  kind                = "Linux"
  reserved            = true
  sku {
    tier = "Dynamic"
    size = "Y1"
  }
  tags = {
    environment = var.environment
    project     = var.project
  }
}

resource "azurerm_network_security_group" "example" {
  name                = "${var.project}-${var.environment}-nsg"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  tags = {
    environment = var.environment
    project     = var.project
  }
}

resource "azurerm_network_security_rule" "example" {
  name                        = "example-rule"
  resource_group_name         = azurerm_resource_group.example.name
  network_security_group_name = azurerm_network_security_group.example.name
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range          = "*"
  destination_port_range     = "22"
  source_address_prefix      = var.ssh_source_cidr
  destination_address_prefix = "*"
}

output "storage_account_name" {
  value = azurerm_storage_account.example.name
}

output "function_app_name" {
  value = azurerm_function_app.example.name
}

output "consumption_plan_name" {
  value = azurerm_app_service_plan.example.name
}