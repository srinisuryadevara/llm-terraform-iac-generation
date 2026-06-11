provider "azurerm" {
  version = "3.34.0"
  features {}
}

variable "location" {
  type        = string
  description = "The location for the resources"
}

variable "resource_group_name" {
  type        = string
  description = "The name of the resource group"
}

variable "cosmos_account_name" {
  type        = string
  description = "The name of the Cosmos DB account"
}

variable "sql_database_name" {
  type        = string
  description = "The name of the SQL database"
}

variable "container_name" {
  type        = string
  description = "The name of the container"
}

variable "tags" {
  type        = map(string)
  description = "The tags for the resources"
}

resource "azurerm_resource_group" "example" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

resource "azurerm_cosmosdb_account" "example" {
  name                = var.cosmos_account_name
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  offer_type          = "Standard"
  kind               = "GlobalDocumentDB"

  enable_automatic_failover = false

  consistency_policy {
    consistency_level = "Session"
  }

  geo_location {
    location          = azurerm_resource_group.example.location
    failover_priority = 0
  }

  tags = var.tags
}

resource "azurerm_cosmosdb_sql_database" "example" {
  name                = var.sql_database_name
  resource_group_name = azurerm_resource_group.example.name
  account_name        = azurerm_cosmosdb_account.example.name
  throughput          = 400

  tags = var.tags
}

resource "azurerm_cosmosdb_sql_container" "example" {
  name                  = var.container_name
  resource_group_name   = azurerm_resource_group.example.name
  account_name          = azurerm_cosmosdb_account.example.name
  database_name         = azurerm_cosmosdb_sql_database.example.name
  partition_key_path    = "/definition"
  partition_key_version = 1
  throughput            = 400

  unique_key {
    paths = ["/definition/idlong", "/definition/idshort"]
  }

  tags = var.tags
}