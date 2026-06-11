provider "azurerm" {
  version = "3.34.0"
  features {}
}

variable "location" {
  type        = string
  description = "Location for resources"
}

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group"
}

variable "app_service_plan_name" {
  type        = string
  description = "Name of the app service plan"
}

variable "app_service_name" {
  type        = string
  description = "Name of the app service"
}

variable "ssh_source_cidr" {
  type        = string
  description = "Source CIDR for SSH"
}

variable "environment" {
  type        = string
  description = "Environment for resources"
}

variable "project" {
  type        = string
  description = "Project for resources"
}

resource "azurerm_resource_group" "example" {
  name     = var.resource_group_name
  location = var.location
  tags = {
    Environment = var.environment
    Project     = var.project
  }
}

resource "azurerm_app_service_plan" "example" {
  name                = var.app_service_plan_name
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  kind                = "Linux"
  reserved            = true
  sku {
    tier = "Standard"
    size = "S1"
  }
  tags = {
    Environment = var.environment
    Project     = var.project
  }
}

resource "azurerm_app_service" "example" {
  name                = var.app_service_name
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  app_service_plan_name = azurerm_app_service_plan.example.name
  https_only          = true
  min_tls_version     = "1.2"
  site_config {
    linux_fx_version = "DOCKER|mcr.microsoft.com/azure-app-service/samples/node:12-lts"
  }
  app_settings = {
    WEBSITE_NODE_DEFAULT_VERSION = "10.15.2"
  }
  tags = {
    Environment = var.environment
    Project     = var.project
  }
}

resource "azurerm_network_security_group" "example" {
  name                = "example-nsg"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  tags = {
    Environment = var.environment
    Project     = var.project
  }
}

resource "azurerm_network_security_rule" "example" {
  name                        = "example-nsg-rule"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range          = "*"
  destination_port_range     = "22"
  source_address_prefix      = var.ssh_source_cidr
  destination_address_prefix = azurerm_app_service.example.default_hostname
  resource_group_name        = azurerm_resource_group.example.name
  network_security_group_name = azurerm_network_security_group.example.name
}

resource "azurerm_storage_account" "example" {
  name                     = "examplestorageaccount"
  resource_group_name      = azurerm_resource_group.example.name
  location                 = azurerm_resource_group.example.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"
  min_tls_version          = "TLS1_2"
  enable_https_traffic_only = true
  tags = {
    Environment = var.environment
    Project     = var.project
  }
}

resource "azurerm_key_vault" "example" {
  name                        = "examplekeyvault"
  location                    = azurerm_resource_group.example.location
  resource_group_name         = azurerm_resource_group.example.name
  tenant_id                   = "your_tenant_id"
  sku_name                    = "standard"
  soft_delete_retention_days  = 7
  enabled_for_disk_encryption = true
  tags = {
    Environment = var.environment
    Project     = var.project
  }
}

resource "azurerm_role_assignment" "example" {
  scope                = azurerm_resource_group.example.id
  role_definition_name = "Contributor"
  principal_id         = "your_principal_id"
}