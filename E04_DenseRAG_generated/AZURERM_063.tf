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

variable "resource_group_name" {
  type        = string
  description = "The name of the resource group"
}

variable "location" {
  type        = string
  description = "The location of the resource group"
}

variable "environment_name" {
  type        = string
  description = "The environment name"
}

variable "cosmosdb_account_name" {
  type        = string
  description = "The name of the Cosmos DB account"
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

resource "azurecaf_name" "rg_name" {
  name          = var.environment_name
  resource_type = "azurerm_resource_group"
  random_length = 0
  clean_input   = true
}

resource "azurerm_resource_group" "rg" {
  name     = azurecaf_name.rg_name.result
  location = var.location

  tags = var.tags
}

resource "azurecaf_name" "db_acc_name" {
  name          = var.cosmosdb_account_name
  resource_type = "azurerm_cosmosdb_account"
  random_length = 0
  clean_input   = true
}

resource "azurerm_cosmosdb_account" "db" {
  name                = azurecaf_name.db_acc_name.result
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  offer_type          = "Standard"
  kind                = "GlobalDocumentDB"
  enable_automatic_failover = false

  consistency_policy {
    consistency_level       = "BoundedStaleness"
    max_interval_in_seconds = 300
    max_staleness_prefix    = 100000
  }

  geo_location {
    location          = var.location
    failover_priority = 0
  }

  tags = var.tags
}

resource "azurerm_cosmosdb_sql_database" "main" {
  name                = var.cosmosdb_sqldb_name
  resource_group_name = azurerm_resource_group.rg.name
  account_name        = azurerm_cosmosdb_account.db.name
}

resource "azurerm_cosmosdb_sql_container" "main" {
  name                  = var.cosmosdb_container_name
  resource_group_name  = azurerm_resource_group.rg.name
  account_name         = azurerm_cosmosdb_account.db.name
  database_name        = azurerm_cosmosdb_sql_database.main.name
  partition_key_path   = "/definition"
  partition_key_version = 1
  throughput            = 400

  indexing_mode = "consistent"

  unique_key {
    paths = ["/definition/idlong", "/definition/idshort"]
  }
}