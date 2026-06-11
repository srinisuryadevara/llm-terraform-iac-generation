locals {
  basename         = "examplestorage"
  location         = "West US"
  resource_group_name = "example-resource-group"
}

terraform {
  backend "azurerm" {
    resource_group_name = local.resource_group_name
    storage_account_name = "examplestorage"
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

  enable_https_traffic_only = true
  allow_blob_public_access  = false
  min_tls_version           = "TLS1_2"

  tags = {
    "CostCenter" = "Example"
  }
}

resource "azurerm_storage_container" "container" {
  name                  = "example"
  storage_account_name  = azurerm_storage_account.storage_account.name
  container_access_type = "private"
}