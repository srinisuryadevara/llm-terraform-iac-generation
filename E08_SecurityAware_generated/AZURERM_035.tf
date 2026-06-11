provider "azurerm" {
  version = "3.34.0"
  features {}
}

variable "region" {
  type        = string
  description = "Azure region"
}

variable "project" {
  type        = string
  description = "Project name"
}

variable "environment" {
  type        = string
  description = "Environment name"
}

variable "event_hub_namespace_name" {
  type        = string
  description = "Event Hub namespace name"
}

variable "event_hub_name" {
  type        = string
  description = "Event Hub name"
}

variable "consumer_group_name" {
  type        = string
  description = "Consumer group name"
}

variable "resource_group_name" {
  type        = string
  description = "Resource group name"
}

resource "azurerm_resource_group" "example" {
  name     = var.resource_group_name
  location = var.region
  tags = {
    environment = var.environment
    project     = var.project
  }
}

resource "azurerm_eventhub_namespace" "example" {
  name                = var.event_hub_namespace_name
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  sku                 = "Standard"
  capacity            = 1
  tags = {
    environment = var.environment
    project     = var.project
  }
}

resource "azurerm_eventhub" "example" {
  name                = var.event_hub_name
  namespace_name      = azurerm_eventhub_namespace.example.name
  resource_group_name = azurerm_resource_group.example.name
  partition_count     = 2
  message_retention   = 1
  tags = {
    environment = var.environment
    project     = var.project
  }
}

resource "azurerm_eventhub_consumer_group" "example" {
  name                = var.consumer_group_name
  namespace_name      = azurerm_eventhub_namespace.example.name
  eventhub_name       = azurerm_eventhub.example.name
  resource_group_name = azurerm_resource_group.example.name
  user_group           = false
  tags = {
    environment = var.environment
    project     = var.project
  }
}

resource "azurerm_storage_account" "example" {
  name                     = "${var.project}${var.environment}storage"
  resource_group_name      = azurerm_resource_group.example.name
  location                 = azurerm_resource_group.example.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"
  min_tls_version          = "TLS1_2"
  tags = {
    environment = var.environment
    project     = var.project
  }
}

resource "azurerm_key_vault" "example" {
  name                        = "${var.project}${var.environment}keyvault"
  location                    = azurerm_resource_group.example.location
  resource_group_name         = azurerm_resource_group.example.name
  tenant_id                   = var.tenant_id
  sku_name                    = "standard"
  soft_delete_retention_days  = 7
  min_tls_version             = "TLS1_2"
  tags = {
    environment = var.environment
    project     = var.project
  }
}

variable "tenant_id" {
  type        = string
  description = "Tenant ID"
}