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

variable "app_service_plan_name" {
  type        = string
  description = "App Service plan name"
}

variable "app_service_name" {
  type        = string
  description = "App Service name"
}

variable "resource_group_name" {
  type        = string
  description = "Resource group name"
}

variable "ssh_source_cidr" {
  type        = string
  description = "SSH source CIDR"
}

variable "storage_account_name" {
  type        = string
  description = "Storage account name"
}

variable "database_username" {
  type        = string
  sensitive   = true
  description = "Database username"
}

variable "database_password" {
  type        = string
  sensitive   = true
  description = "Database password"
}

resource "azurerm_resource_group" "example" {
  name     = var.resource_group_name
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

resource "azurerm_app_service_plan" "example" {
  name                = var.app_service_plan_name
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  kind                = "Linux"
  reserved            = true
  sku {
    tier = "Standard"
    size = "S1"
  }
  tags = {
    environment = var.environment
    project     = var.project
  }
}

resource "azurerm_app_service" "example" {
  name                = var.app_service_name
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  app_service_plan_name = azurerm_app_service_plan.example.name
  https_only          = true
  min_tls_version     = "1.2"
  site_config {
    linux_fx_version = "DOCKER|mcr.microsoft.com/azure-app-service/samples/node:12-lts"
  }
  app_settings = {
    WEBSITE_NODE_DEFAULT_VERSION = "10.15.2"
    DATABASE_USERNAME           = var.database_username
    DATABASE_PASSWORD           = var.database_password
  }
  tags = {
    environment = var.environment
    project     = var.project
  }
}

resource "azurerm_network_security_group" "example" {
  name                = "example-nsg"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  tags = {
    environment = var.environment
    project     = var.project
  }
}

resource "azurerm_network_security_rule" "example" {
  name                        = "example-nsg-rule"
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

resource "azurerm_postgresql_server" "example" {
  name                = "example-psql-server"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  sku_name            = "GP_Gen5_2"
  version             = "11"
  storage_mb          = 5120
  ssl_enforcement     = "Enabled"
  ssl_minimal_tls_version = "TLS1_2"
  administrator_login          = var.database_username
  administrator_login_password = var.database_password
  tags = {
    environment = var.environment
    project     = var.project
  }
}

resource "azurerm_postgresql_database" "example" {
  name  = "example-psql-db"
  resource_group_name = azurerm_resource_group.example.name
  server_name = azurerm_postgresql_server.example.name
  charset   = "UTF8"
  collation = "English_United States.1252"
  depends_on = [azurerm_postgresql_server.example]
  tags = {
    environment = var.environment
    project     = var.project
  }
}