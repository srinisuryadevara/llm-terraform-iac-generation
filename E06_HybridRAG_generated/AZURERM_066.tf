terraform {
  required_version = ">= 1.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.47.0"
    }
    azurecaf = {
      source  = "aztfmod/azurecaf"
      version = "~>1.2.24"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

variable "resource_token" {
  type        = string
  sensitive   = true
  description = "Resource token"
}

variable "location" {
  type        = string
  sensitive   = false
  description = "Location"
}

variable "rg_name" {
  type        = string
  sensitive   = false
  description = "Resource group name"
}

variable "tags" {
  type        = map(string)
  sensitive   = false
  description = "Tags"
}

variable "cosmosdb_account_name" {
  type        = string
  sensitive   = false
  description = "Cosmos DB account name"
}

variable "cosmosdb_account_location" {
  type        = string
  sensitive   = false
  description = "Cosmos DB account location"
}

variable "cosmosdb_sqldb_name" {
  type        = string
  sensitive   = false
  description = "Cosmos DB SQL database name"
}

variable "cosmosdb_container_name" {
  type        = string
  sensitive   = false
  description = "Cosmos DB container name"
}

resource "azurecaf_name" "db_acc_name" {
  name          = var.resource_token
  resource_type = "azurerm_cosmosdb_account"
  random_length = 0
  clean_input   = true
}

resource "azurerm_cosmosdb_account" "db" {
  name                            = azurecaf_name.db_acc_name.result
  location                        = var.location
  resource_group_name             = var.rg_name
  offer_type                      = "Standard"
  kind                            = "GlobalDocumentDB"
  enable_automatic_failover       = false
  enable_multiple_write_locations = false
  tags                            = var.tags

  consistency_policy {
    consistency_level = "Session"
  }

  geo_location {
    location          = var.location
    failover_priority = 0
    zone_redundant    = false
  }
}

resource "azurerm_cosmosdb_sql_database" "main" {
  name                = var.cosmosdb_sqldb_name
  resource_group_name = var.rg_name
  account_name        = azurecaf_name.db_acc_name.result
}

resource "azurerm_cosmosdb_sql_container" "main" {
  name                  = var.cosmosdb_container_name
  resource_group_name   = var.rg_name
  account_name          = azurecaf_name.db_acc_name.result
  database_name         = azurerm_cosmosdb_sql_database.main.name
  partition_key_path    = "/definition"
  partition_key_version = 1
  throughput            = 400
}