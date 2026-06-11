provider "azurerm" {
  version = "3.34.0"
  features {}
}

variable "project_name" {
  type        = string
  description = "Project name"
}

variable "environment" {
  type        = string
  description = "Environment"
}

variable "location" {
  type        = string
  description = "Location"
}

variable "resource_group_name" {
  type        = string
  description = "Resource group name"
}

variable "postgresql_server_name" {
  type        = string
  description = "PostgreSQL server name"
}

variable "postgresql_admin_username" {
  type        = string
  sensitive   = true
  description = "PostgreSQL admin username"
}

variable "postgresql_admin_password" {
  type        = string
  sensitive   = true
  description = "PostgreSQL admin password"
}

variable "private_dns_zone_name" {
  type        = string
  description = "Private DNS zone name"
}

variable "vnet_cidr" {
  type        = string
  description = "VNet CIDR"
}

variable "subnet_cidr" {
  type        = string
  description = "Subnet CIDR"
}

variable "allowed_ssh_cidr" {
  type        = string
  description = "Allowed SSH CIDR"
}

resource "azurerm_resource_group" "example" {
  name     = var.resource_group_name
  location = var.location
  tags = {
    project     = var.project_name
    environment = var.environment
  }
}

resource "azurerm_virtual_network" "example" {
  name                = "${var.project_name}-vnet"
  address_space       = [var.vnet_cidr]
  location            = var.location
  resource_group_name = azurerm_resource_group.example.name
  tags = {
    project     = var.project_name
    environment = var.environment
  }
}

resource "azurerm_subnet" "example" {
  name                 = "${var.project_name}-subnet"
  resource_group_name = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.example.name
  address_prefixes     = [var.subnet_cidr]
}

resource "azurerm_private_dns_zone" "example" {
  name                = var.private_dns_zone_name
  resource_group_name = azurerm_resource_group.example.name
  tags = {
    project     = var.project_name
    environment = var.environment
  }
}

resource "azurerm_private_dns_zone_virtual_network_link" "example" {
  name                  = "${var.project_name}-link"
  resource_group_name   = azurerm_resource_group.example.name
  private_dns_zone_name = azurerm_private_dns_zone.example.name
  virtual_network_id    = azurerm_virtual_network.example.id
}

resource "azurerm_postgresql_flexible_server" "example" {
  name                = var.postgresql_server_name
  resource_group_name = azurerm_resource_group.example.name
  location            = var.location
  sku_name            = "GP_Standard_D2ds_v4"
  storage_mb          = 32768
  admin_login         = var.postgresql_admin_username
  admin_password      = var.postgresql_admin_password
  version             = "13"
  zone                = "1"
  tags = {
    project     = var.project_name
    environment = var.environment
  }
  ssl_enforcement_enabled = true
  ssl_minimal_tls_version = "TLS1_2"
}

resource "azurerm_postgresql_flexible_server_configuration" "example" {
  name                = "require_secure_transport"
  resource_group_name = azurerm_resource_group.example.name
  server_name         = azurerm_postgresql_flexible_server.example.name
  value               = "ON"
}

resource "azurerm_network_security_group" "example" {
  name                = "${var.project_name}-nsg"
  location            = var.location
  resource_group_name = azurerm_resource_group.example.name
  tags = {
    project     = var.project_name
    environment = var.environment
  }
}

resource "azurerm_network_security_rule" "example" {
  name                        = "allow-ssh"
  resource_group_name         = azurerm_resource_group.example.name
  network_security_group_name = azurerm_network_security_group.example.name
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range          = "*"
  destination_port_range     = "22"
  source_address_prefix      = var.allowed_ssh_cidr
  destination_address_prefix = azurerm_subnet.example.address_prefix
}

resource "azurerm_subnet_network_security_group_association" "example" {
  subnet_id                 = azurerm_subnet.example.id
  network_security_group_id = azurerm_network_security_group.example.id
}