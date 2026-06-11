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
  description = "Environment name"
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

resource "azurerm_resource_group" "this" {
  name     = var.resource_group_name
  location = var.location
  tags = {
    project     = var.project_name
    environment = var.environment
  }
}

resource "azurerm_virtual_network" "this" {
  name                = "${var.project_name}-vnet"
  address_space       = [var.vnet_cidr]
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name
  tags = {
    project     = var.project_name
    environment = var.environment
  }
}

resource "azurerm_subnet" "this" {
  name                 = "${var.project_name}-subnet"
  resource_group_name = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = [var.subnet_cidr]
  service_endpoints    = ["Microsoft.AzureCosmosDB", "Microsoft.Storage"]
  delegation {
    name = "delegation"
    service_delegation {
      name    = "Microsoft.DBforPostgreSQL/flexibleServers"
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
    }
  }
  tags = {
    project     = var.project_name
    environment = var.environment
  }
}

resource "azurerm_private_dns_zone" "this" {
  name                = var.private_dns_zone_name
  resource_group_name = azurerm_resource_group.this.name
  tags = {
    project     = var.project_name
    environment = var.environment
  }
}

resource "azurerm_private_dns_zone_virtual_network_link" "this" {
  name                  = "${var.project_name}-link"
  resource_group_name   = azurerm_resource_group.this.name
  private_dns_zone_name = azurerm_private_dns_zone.this.name
  virtual_network_id    = azurerm_virtual_network.this.id
  tags = {
    project     = var.project_name
    environment = var.environment
  }
}

resource "azurerm_postgresql_flexible_server" "this" {
  name                = var.postgresql_server_name
  resource_group_name = azurerm_resource_group.this.name
  location            = var.location
  sku_name            = "GP_Standard_D2ds_v4"
  storage_mb          = 32768
  admin_login         = var.postgresql_admin_username
  admin_password      = var.postgresql_admin_password
  version             = "13"
  zone                = "1"
  create_mode         = "Default"
  public_network_access_enabled = false
  private_dns_zone_id = azurerm_private_dns_zone.this.id
  delegated_subnet_id = azurerm_subnet.this.id
  tags = {
    project     = var.project_name
    environment = var.environment
  }
}

resource "azurerm_network_security_group" "this" {
  name                = "${var.project_name}-nsg"
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name
  tags = {
    project     = var.project_name
    environment = var.environment
  }
}

resource "azurerm_network_security_rule" "ssh" {
  name                        = "SSH"
  resource_group_name         = azurerm_resource_group.this.name
  network_security_group_name = azurerm_network_security_group.this.name
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_address_prefix       = var.allowed_ssh_cidr
  source_port_range          = "*"
  destination_address_prefix  = azurerm_subnet.this.address_prefixes[0]
  destination_port_range     = "22"
  tags = {
    project     = var.project_name
    environment = var.environment
  }
}

resource "azurerm_network_security_rule" "postgresql" {
  name                        = "PostgreSQL"
  resource_group_name         = azurerm_resource_group.this.name
  network_security_group_name = azurerm_network_security_group.this.name
  priority                    = 200
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_address_prefix       = var.allowed_ssh_cidr
  source_port_range          = "*"
  destination_address_prefix  = azurerm_subnet.this.address_prefixes[0]
  destination_port_range     = "5432"
  tags = {
    project     = var.project_name
    environment = var.environment
  }
}

resource "azurerm_subnet_network_security_group_association" "this" {
  subnet_id                 = azurerm_subnet.this.id
  network_security_group_id = azurerm_network_security_group.this.id
}