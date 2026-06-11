terraform {
  required_providers {
    aws = {
      version = "~> 4.0"
      source  = "hashicorp/aws"
    }
    azurerm = {
      version = "~> 3.47.0"
      source  = "hashicorp/azurerm"
    }
    google = {
      version = "~> 4.0"
      source  = "hashicorp/google"
    }
  }
}

variable "aws_region" {
  default = "us-west-2"
}

variable "aws_access_key" {}
variable "aws_secret_key" {}

variable "azure_subscription_id" {}
variable "azure_client_id" {}
variable "azure_client_secret" {}
variable "azure_tenant_id" {}
variable "azure_location" {
  default = "West US"
}

variable "gcp_project" {}
variable "gcp_region" {
  default = "us-central1"
}
variable "gcp_credentials" {}

variable "secrets" {
  type = map(string)
}

provider "aws" {
  region     = var.aws_region
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}

provider "azurerm" {
  subscription_id = var.azure_subscription_id
  client_id       = var.azure_client_id
  client_secret   = var.azure_client_secret
  tenant_id       = var.azure_tenant_id
  features {}
}

provider "google" {
  project = var.gcp_project
  region  = var.gcp_region
  credentials = var.gcp_credentials
}

resource "aws_secretsmanager_secret" "aws_secrets" {
  for_each = var.secrets
  name     = each.key
  value    = each.value
}

resource "azurerm_key_vault" "azure_key_vault" {
  name                     = "examplekeyvault"
  location                 = var.azure_location
  resource_group_name      = "example-resource-group"
  tenant_id                = var.azure_tenant_id
  sku_name                 = "standard"
}

resource "azurerm_key_vault_access_policy" "azure_access_policy" {
  key_vault_id = azurerm_key_vault.azure_key_vault.id
  tenant_id    = var.azure_tenant_id
  object_id    = var.azure_client_id

  secret_permissions = [
    "Get",
    "Set",
    "List",
    "Delete",
  ]
}

resource "azurerm_key_vault_secret" "azure_secrets" {
  depends_on   = [azurerm_key_vault_access_policy.azure_access_policy]
  for_each     = var.secrets
  name         = each.key
  value        = each.value
  key_vault_id = azurerm_key_vault.azure_key_vault.id
}

resource "google_secret_manager_secret" "gcp_secrets" {
  for_each = var.secrets
  secret_id = each.key
  replication {
    automatic = true
  }
}

resource "google_secret_manager_secret_version" "gcp_secret_versions" {
  for_each = var.secrets
  secret   = google_secret_manager_secret.gcp_secrets[each.key].id
  secret_data = each.value
}