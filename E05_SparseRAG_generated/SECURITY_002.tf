locals {
  basename        = "azurestorage"
  location        = "West US"
  resource_group_name = "azure-rg"
}

terraform {
  backend "azurerm" {
    resource_group_name = local.resource_group_name
    storage_account_name = "terraformstate123"
    container_name       = "terraform-state"
    key                  = "terraform.tfstate"
  }
}

provider "azurerm" {
  features {}
}

data "azurerm_resource_group" "rg" {
  name = local.resource_group_name
}

resource "azurerm_storage_account" "storage_account" {
  name                     = local.basename
  resource_group_name      = data.azurerm_resource_group.rg.name
  location                 = local.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"

  min_tls_version = "TLS1_2"

  blob_properties {
    cors_rule {
      allowed_headers = ["*"]
      allowed_methods = ["GET", "HEAD", "OPTIONS", "PUT"]
      allowed_origins = ["*"]
      exposed_headers = ["*"]
      max_age_seconds = 200
    }
  }

  network_rules {
    default_action             = "Deny"
    ip_rules                   = []
    virtual_network_subnet_ids = []
    bypass                     = ["AzureServices"]
  }

  tags = {
    "CostCenter" = "SpikeReply"
  }
}

resource "azurerm_storage_container" "container" {
  name                  = "private"
  storage_account_name  = azurerm_storage_account.storage_account.name
  container_access_type = "private"
}