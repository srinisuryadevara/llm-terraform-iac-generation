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

variable "ssh_source_cidr" {
  type        = string
  description = "SSH source CIDR"
}

variable "db_admin_username" {
  type        = string
  sensitive   = true
  description = "Database admin username"
}

variable "db_admin_password" {
  type        = string
  sensitive   = true
  description = "Database admin password"
}

variable "db_name" {
  type        = string
  description = "Database name"
}

resource "azurerm_resource_group" "example" {
  name     = "${var.project}-${var.environment}-rg"
  location = var.region
  tags = {
    environment = var.environment
    project     = var.project
  }
}

resource "azurerm_private_dns_zone" "example" {
  name                = "example.postgres.database.azure.com"
  resource_group_name = azurerm_resource_group.example.name
  tags = {
    environment = var.environment
    project     = var.project
  }
}

resource "azurerm_private_dns_zone_virtual_network_link" "example" {
  name                  = "${var.project}-${var.environment}-link"
  resource_group_name   = azurerm_resource_group.example.name
  private_dns_zone_name = azurerm_private_dns_zone.example.name
  virtual_network_id    = azurerm_virtual_network.example.id
  tags = {
    environment = var.environment
    project     = var.project
  }
}

resource "azurerm_virtual_network" "example" {
  name                = "${var.project}-${var.environment}-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = var.region
  resource_group_name = azurerm_resource_group.example.name
  tags = {
    environment = var.environment
    project     = var.project
  }
}

resource "azurerm_subnet" "example" {
  name                 = "${var.project}-${var.environment}-subnet"
  resource_group_name = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.example.name
  address_prefixes     = ["10.0.1.0/24"]
  tags = {
    environment = var.environment
    project     = var.project
  }
}

resource "azurerm_postgresql_flexible_server" "example" {
  name                = "${var.project}-${var.environment}-psql"
  resource_group_name = azurerm_resource_group.example.name
  location            = var.region
  version             = "13"

  sku_name = "GP_Standard_D2ds_v4"

  storage_mb = 32768

  administrator_login    = var.db_admin_username
  administrator_password = var.db_admin_password

  zone               = "1"
  db_name             = var.db_name
  create_mode         = "Default"
  deletion_protection = false

  private_dns_zone_id = azurerm_private_dns_zone.example.id

  tags = {
    environment = var.environment
    project     = var.project
  }
}

resource "azurerm_network_security_group" "example" {
  name                = "${var.project}-${var.environment}-nsg"
  location            = var.region
  resource_group_name = azurerm_resource_group.example.name
  tags = {
    environment = var.environment
    project     = var.project
  }
}

resource "azurerm_network_security_rule" "example" {
  name                        = "SSH"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range          = "*"
  destination_port_range     = "22"
  source_address_prefix      = var.ssh_source_cidr
  destination_address_prefix = azurerm_subnet.example.address_prefixes[0]
  resource_group_name         = azurerm_resource_group.example.name
  network_security_group_name = azurerm_network_security_group.example.name
}

resource "azurerm_subnet_network_security_group_association" "example" {
  subnet_id                 = azurerm_subnet.example.id
  network_security_group_id = azurerm_network_security_group.example.id
}

resource "azurerm_storage_account" "example" {
  name                     = "${var.project}${var.environment}storage"
  resource_group_name      = azurerm_resource_group.example.name
  location                 = var.region
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"

  min_tls_version = "TLS1_2"

  tags = {
    environment = var.environment
    project     = var.project
  }
}

resource "azurerm_storage_container" "example" {
  name                  = "${var.project}-${var.environment}-container"
  storage_account_name  = azurerm_storage_account.example.name
  container_access_type = "private"
  tags = {
    environment = var.environment
    project     = var.project
  }
}