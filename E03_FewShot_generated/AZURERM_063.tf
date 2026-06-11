provider "azurerm" {
  version = "3.34.0"
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

variable "cosmos_account_name" {
  type        = string
  description = "The name of the Cosmos DB account"
}

variable "cosmos_account_offer_type" {
  type        = string
  description = "The offer type of the Cosmos DB account"
  default     = "Standard"
}

variable "cosmos_account_kind" {
  type        = string
  description = "The kind of the Cosmos DB account"
  default     = "GlobalDocumentDB"
}

variable "sql_database_name" {
  type        = string
  description = "The name of the SQL database"
}

variable "sql_container_name" {
  type        = string
  description = "The name of the SQL container"
}

variable "sql_container_partition_key_path" {
  type        = string
  description = "The partition key path of the SQL container"
  default     = "/id"
}

variable "sql_container_throughput" {
  type        = number
  description = "The throughput of the SQL container"
  default     = 400
}

resource "azurerm_resource_group" "example" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_cosmosdb_account" "example" {
  name                = var.cosmos_account_name
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  offer_type          = var.cosmos_account_offer_type
  kind                = var.cosmos_account_kind

  enable_automatic_failover = false

  consistency_policy {
    consistency_level = "Session"
  }

  geo_location {
    location          = azurerm_resource_group.example.location
    failover_priority = 0
  }
}

resource "azurerm_cosmosdb_sql_database" "example" {
  name                = var.sql_database_name
  resource_group_name = azurerm_resource_group.example.name
  account_name        = azurerm_cosmosdb_account.example.name
}

resource "azurerm_cosmosdb_sql_container" "example" {
  name                  = var.sql_container_name
  resource_group_name   = azurerm_resource_group.example.name
  account_name          = azurerm_cosmosdb_account.example.name
  database_name         = azurerm_cosmosdb_sql_database.example.name
  partition_key_path    = var.sql_container_partition_key_path
  partition_key_version = 1
  throughput            = var.sql_container_throughput
}