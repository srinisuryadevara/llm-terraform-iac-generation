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

variable "allowed_cidr" {
  type        = string
  description = "Allowed CIDR for SSH"
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

variable "storage_account_key" {
  type        = string
  sensitive   = true
  description = "Storage account key"
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
}

resource "azurerm_function_app" "example" {
  name                       = var.function_app_name
  location                   = azurerm_resource_group.example.location
  resource_group_name        = azurerm_resource_group.example.name
  app_service_plan_name      = azurerm_app_service_plan.example.name
  storage_account_name       = azurerm_storage_account.example.name
  storage_account_access_key = var.storage_account_key
  os_type                    = "linux"
  version                    = "~4"

  site_config {
    min_tls_version = "1.2"
  }

  tags = {
    environment = var.environment
    project     = var.project
  }
}

resource "azurerm_app_service_plan" "example" {
  name                = var.consumption_plan_name
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
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
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name

  security_rule {
    name                       = "SSH"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = var.allowed_cidr
    destination_address_prefix = "*"
  }

  tags = {
    environment = var.environment
    project     = var.project
  }
}