terraform {
  required_version = ">= 1.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.0, < 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.0"
    }
    azurecaf = {
      source  = "aztfmod/azurecaf"
      version = "~>1.2.24"
    }
  }
}

provider "azurerm" {
  features {}
}

variable "location" {
  type        = string
  description = "The location of the resource group"
}

variable "resource_group_name" {
  type        = string
  description = "The name of the resource group"
}

variable "cosmosdb_account_name" {
  type        = string
  description = "The name of the Cosmos DB account"
}

variable "cosmosdb_account_location" {
  type        = string
  description = "The location of the Cosmos DB account"
}

variable "cosmosdb_sqldb_name" {
  type        = string
  description = "The name of the Cosmos DB SQL database"
}

variable "cosmosdb_container_name" {
  type        = string
  description = "The name of the Cosmos DB container"
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

resource "random_string" "db_account_name" {
  count = var.cosmosdb_account_name == null ? 1 : 0

  length  = 20
  upper   = false
  special = false
  numeric = false
}

locals {
  cosmosdb_account_name = try(random_string.db_account_name[0].result, var.cosmosdb_account_name)
}

resource "azurerm_cosmosdb_account" "example" {
  name                      = local.cosmosdb_account_name
  location                  = var.cosmosdb_account_location
  resource_group_name       = azurerm_resource_group.example.name
  offer_type                = "Standard"
  kind                      = "GlobalDocumentDB"
  enable_automatic_failover = false
  geo_location {
    location          = var.cosmosdb_account_location
    failover_priority = 0
  }
  consistency_policy {
    consistency_level       = "BoundedStaleness"
    max_interval_in_seconds = 300
    max_staleness_prefix    = 100000
  }
  depends_on = [
    azurerm_resource_group.example
  ]
}

resource "azurerm_cosmosdb_sql_database" "main" {
  name                = var.cosmosdb_sqldb_name
  resource_group_name = azurerm_resource_group.example.name
  account_name        = azurerm_cosmosdb_account.example.name
}

resource "azurerm_cosmosdb_sql_container" "example" {
  name                  = var.cosmosdb_container_name
  resource_group_name  = azurerm_resource_group.example.name
  account_name         = azurerm_cosmosdb_account.example.name
  database_name        = azurerm_cosmosdb_sql_database.main.name
  partition_key_path   = "/definition"
  partition_key_version = 1
  throughput            = 400
}