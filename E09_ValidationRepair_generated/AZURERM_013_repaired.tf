provider "azurerm" {
  version = "3.34.0"
  features {}
}

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group"
}

variable "location" {
  type        = string
  description = "Location of the resource group"
}

variable "cosmos_account_name" {
  type        = string
  description = "Name of the Cosmos DB account"
}

variable "cosmos_account_key" {
  type        = string
  sensitive   = true
  description = "Key of the Cosmos DB account"
}

resource "azurerm_resource_group" "example" {
  name     = var.resource_group_name
  location = var.location
  tags = {
    environment = "example"
  }
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
  tags = {
    environment = "example"
  }
}

resource "azurerm_cosmosdb_sql_database" "example" {
  name                = "example-sql-database"
  resource_group_name = azurerm_resource_group.example.name
  account_name        = azurerm_cosmosdb_account.example.name
  throughput          = 400
  tags = {
    environment = "example"
  }
}

resource "azurerm_cosmosdb_sql_container" "example" {
  name                  = "example-sql-container"
  resource_group_name   = azurerm_resource_group.example.name
  account_name          = azurerm_cosmosdb_account.example.name
  database_name         = azurerm_cosmosdb_sql_database.example.name
  partition_key_path    = "/definition"
  partition_key_version = 1
  throughput            = 400

  unique_key {
    paths = ["/definition/id(long)"]
  }
  tags = {
    environment = "example"
  }
}

output "resource_group_id" {
  value = azurerm_resource_group.example.id
}

output "cosmos_account_id" {
  value = azurerm_cosmosdb_account.example.id
}

output "cosmos_account_endpoint" {
  value = azurerm_cosmosdb_account.example.endpoint
}

output "sql_database_id" {
  value = azurerm_cosmosdb_sql_database.example.id
}

output "sql_container_id" {
  value = azurerm_cosmosdb_sql_container.example.id
}