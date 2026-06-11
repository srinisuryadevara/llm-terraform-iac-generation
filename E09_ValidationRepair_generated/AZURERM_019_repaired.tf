provider "azurerm" {
  features {}
}

variable "resource_group_name" {
  type        = string
  description = "The name of the resource group"
}

variable "location" {
  type        = string
  description = "The location of the resource group"
}

variable "postgresql_server_name" {
  type        = string
  description = "The name of the PostgreSQL Flexible Server"
}

variable "postgresql_admin_username" {
  type        = string
  sensitive   = true
  description = "The administrator username for the PostgreSQL Flexible Server"
}

variable "postgresql_admin_password" {
  type        = string
  sensitive   = true
  description = "The administrator password for the PostgreSQL Flexible Server"
}

variable "postgresql_version" {
  type        = string
  default     = "13"
  description = "The version of PostgreSQL"
}

variable "postgresql_sku_name" {
  type        = string
  default     = "GP_Standard_D2ds_v4"
  description = "The SKU name of the PostgreSQL Flexible Server"
}

variable "private_dns_zone_name" {
  type        = string
  default     = "privatelink.postgres.database.azure.com"
  description = "The name of the private DNS zone"
}

variable "vnet_name" {
  type        = string
  description = "The name of the virtual network"
}

variable "subnet_name" {
  type        = string
  description = "The name of the subnet"
}

resource "azurerm_resource_group" "example" {
  name     = var.resource_group_name
  location = var.location
  tags = {
    environment = "example"
  }
}

resource "azurerm_virtual_network" "example" {
  name                = var.vnet_name
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  tags = {
    environment = "example"
  }
}

resource "azurerm_subnet" "example" {
  name                 = var.subnet_name
  resource_group_name = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.example.name
  address_prefixes     = ["10.0.1.0/24"]
  tags = {
    environment = "example"
  }
}

resource "azurerm_postgresql_flexible_server" "example" {
  name                = var.postgresql_server_name
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location

  sku_name = var.postgresql_sku_name

  admin_login    = var.postgresql_admin_username
  admin_password = var.postgresql_admin_password

  version = var.postgresql_version

  delegated_subnet_id = azurerm_subnet.example.id
  private_dns_zone_id = azurerm_private_dns_zone.example.id
  tags = {
    environment = "example"
  }
}

resource "azurerm_private_dns_zone" "example" {
  name                = var.private_dns_zone_name
  resource_group_name = azurerm_resource_group.example.name
  tags = {
    environment = "example"
  }
}

resource "azurerm_private_dns_zone_virtual_network_link" "example" {
  name                  = "example"
  resource_group_name   = azurerm_resource_group.example.name
  private_dns_zone_name = azurerm_private_dns_zone.example.name
  virtual_network_id    = azurerm_virtual_network.example.id
  tags = {
    environment = "example"
  }
}

resource "azurerm_private_endpoint" "example" {
  name                = "example"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  subnet_id           = azurerm_subnet.example.id

  private_service_connection {
    name                           = "example"
    private_connection_resource_id = azurerm_postgresql_flexible_server.example.id
    subresource_names              = ["postgresqlServer"]
    is_manual_connection           = false
  }
  tags = {
    environment = "example"
  }
}

output "resource_group_id" {
  value = azurerm_resource_group.example.id
}

output "postgresql_server_id" {
  value = azurerm_postgresql_flexible_server.example.id
}

output "postgresql_server_endpoint" {
  value = azurerm_postgresql_flexible_server.example.fqdn
}

output "private_dns_zone_id" {
  value = azurerm_private_dns_zone.example.id
}

output "private_endpoint_id" {
  value = azurerm_private_endpoint.example.id
}