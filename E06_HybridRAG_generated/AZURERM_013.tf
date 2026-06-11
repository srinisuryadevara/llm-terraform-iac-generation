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

variable "location" {
  type        = string
  description = "The location of the resource group"
}

variable "resource_token" {
  type        = string
  description = "The resource token"
}

variable "rg_name" {
  type        = string
  description = "The name of the resource group"
}

variable "tags" {
  type        = map(string)
  description = "The tags for the resource"
}

variable "cosmosdb_account_name" {
  type        = string
  default     = null
  description = "The name of the Cosmos DB account"
}

variable "cosmosdb_account_location" {
  type        = string
  default     = null
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

variable "cosmosdb_container_partition_key_path" {
  type        = string
  description = "The partition key path for the Cosmos DB container"
}

variable "cosmosdb_container_throughput" {
  type        = number
  description = "The throughput for the Cosmos DB container"
}

resource "azurecaf_name" "db_acc_name" {
  name          = var.resource_token
  resource_type = "azurerm_cosmosdb_account"
  random_length = 0
  clean_input   = true
}

resource "azurerm_cosmosdb_account" "db" {
  name                            = var.cosmosdb_account_name != null ? var.cosmosdb_account_name : azurecaf_name.db_acc_name.result
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
  account_name        = azurerm_cosmosdb_account.db.name
}

resource "azurerm_cosmosdb_sql_container" "main" {
  name                  = var.cosmosdb_container_name
  resource_group_name   = var.rg_name
  account_name          = azurerm_cosmosdb_account.db.name
  database_name         = azurerm_cosmosdb_sql_database.main.name
  partition_key_path    = var.cosmosdb_container_partition_key_path
  partition_key_version = 1
  throughput            = var.cosmosdb_container_throughput
}