variable "resource_group_name" {
  type        = string
  description = "The name of the resource group"
}

variable "location" {
  type        = string
  description = "The location of the resource group"
}

variable "sqlserverdb" {
  type        = string
  description = "The name of the SQL server database"
}

variable "pgdatabase" {
  type        = string
  description = "The name of the PostgreSQL database"
}

variable "private_dns_zone" {
  type        = string
  description = "The name of the private DNS zone"
}

variable "postgresql_server_name" {
  type        = string
  description = "The name of the PostgreSQL server"
}

variable "postgresql_server_password" {
  type        = string
  sensitive   = true
  description = "The password of the PostgreSQL server"
}

variable "postgresql_server_port" {
  type        = number
  description = "The port of the PostgreSQL server"
}

variable "postgresql_server_sku" {
  type        = string
  description = "The SKU of the PostgreSQL server"
}

variable "postgresql_server_version" {
  type        = string
  description = "The version of the PostgreSQL server"
}

variable "postgresql_server_admin_login" {
  type        = string
  description = "The admin login of the PostgreSQL server"
}

variable "postgresql_server_admin_password" {
  type        = string
  sensitive   = true
  description = "The admin password of the PostgreSQL server"
}

variable "postgresql_server_storage_mb" {
  type        = number
  description = "The storage MB of the PostgreSQL server"
}

variable "postgresql_server_backup_retention_days" {
  type        = number
  description = "The backup retention days of the PostgreSQL server"
}

variable "postgresql_server_geo_redundant_backup_enabled" {
  type        = bool
  description = "The geo redundant backup enabled of the PostgreSQL server"
}

variable "postgresql_server_geo_redundant_backup" {
  type        = bool
  description = "The geo redundant backup of the PostgreSQL server"
}

variable "postgresql_server_zone_redundant" {
  type        = bool
  description = "The zone redundant of the PostgreSQL server"
}

variable "postgresql_server_zone" {
  type        = string
  description = "The zone of the PostgreSQL server"
}

variable "private_dns_zone_group_name" {
  type        = string
  description = "The name of the private DNS zone group"
}

variable "virtual_network_id" {
  type        = string
  description = "The ID of the virtual network"
}

variable "subnet_id" {
  type        = string
  description = "The ID of the subnet"
}

resource "azurerm_resource_group" "example" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_postgresql_flexible_server" "example" {
  name                = var.postgresql_server_name
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location

  sku_name = var.postgresql_server_sku

  admin_login    = var.postgresql_server_admin_login
  admin_password = var.postgresql_server_admin_password

  storage_mb = var.postgresql_server_storage_mb

  backup_retention_days = var.postgresql_server_backup_retention_days

  geo_redundant_backup_enabled = var.postgresql_server_geo_redundant_backup_enabled

  zone = var.postgresql_server_zone

  depends_on = [
    azurerm_resource_group.example
  ]
}

resource "azurerm_private_dns_zone" "example" {
  name                = var.private_dns_zone
  resource_group_name = azurerm_resource_group.example.name

  depends_on = [
    azurerm_resource_group.example
  ]
}

resource "azurerm_private_dns_zone_group" "example" {
  name                  = var.private_dns_zone_group_name
  private_dns_zone_name = azurerm_private_dns_zone.example.name
  resource_group_name   = azurerm_resource_group.example.name
  virtual_network_id    = var.virtual_network_id

  depends_on = [
    azurerm_private_dns_zone.example,
    azurerm_resource_group.example
  ]
}

resource "azurerm_postgresql_flexible_database" "example" {
  name      = var.pgdatabase
  server_id = azurerm_postgresql_flexible_server.example.id

  depends_on = [
    azurerm_postgresql_flexible_server.example
  ]
}

resource "azurerm_private_dns_a_record" "example" {
  name                = "example"
  zone_name           = azurerm_private_dns_zone.example.name
  resource_group_name = azurerm_resource_group.example.name
  ttl                 = 300
  records             = [azurerm_postgresql_flexible_server.example.private_endpoint]

  depends_on = [
    azurerm_postgresql_flexible_server.example,
    azurerm_private_dns_zone.example
  ]
}