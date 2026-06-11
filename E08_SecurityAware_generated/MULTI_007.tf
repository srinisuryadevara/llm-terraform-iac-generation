# AWS Secrets Manager
provider "aws" {
  region = var.aws_region
}

resource "aws_secretsmanager_secret" "secret" {
  name        = var.secret_name
  description = var.secret_description
  tags = {
    Environment = var.environment
    Project     = var.project
  }
}

resource "aws_secretsmanager_secret_version" "secret_version" {
  secret_id     = aws_secretsmanager_secret.secret.id
  secret_string = var.secret_value
}

# Azure Key Vault
provider "azurerm" {
  features {}
  subscription_id = var.azure_subscription_id
  client_id       = var.azure_client_id
  client_secret   = var.azure_client_secret
  tenant_id       = var.azure_tenant_id
}

resource "azurerm_resource_group" "key_vault" {
  name     = var.key_vault_resource_group
  location = var.azure_location
  tags = {
    Environment = var.environment
    Project     = var.project
  }
}

resource "azurerm_key_vault" "key_vault" {
  name                        = var.key_vault_name
  location                    = azurerm_resource_group.key_vault.location
  resource_group_name         = azurerm_resource_group.key_vault.name
  tenant_id                   = var.azure_tenant_id
  sku_name                    = "standard"
  soft_delete_retention_days  = 7
  purge_protection_enabled    = true
  enabled_for_disk_encryption = true
  tags = {
    Environment = var.environment
    Project     = var.project
  }
}

resource "azurerm_key_vault_secret" "secret" {
  name         = var.secret_name
  value        = var.secret_value
  key_vault_id = azurerm_key_vault.key_vault.id
}

# GCP Secret Manager
provider "google" {
  project = var.gcp_project
  region  = var.gcp_region
}

resource "google_secretmanager_secret" "secret" {
  secret_id = var.secret_name
  replication {
    automatic = true
  }
  labels = {
    Environment = var.environment
    Project     = var.project
  }
}

resource "google_secretmanager_secret_version" "secret_version" {
  secret      = google_secretmanager_secret.secret.id
  secret_data = var.secret_value
}

# Variables
variable "aws_region" {
  type        = string
  sensitive   = true
  description = "AWS Region"
}

variable "secret_name" {
  type        = string
  sensitive   = true
  description = "Secret Name"
}

variable "secret_description" {
  type        = string
  sensitive   = true
  description = "Secret Description"
}

variable "secret_value" {
  type        = string
  sensitive   = true
  description = "Secret Value"
}

variable "environment" {
  type        = string
  sensitive   = true
  description = "Environment"
}

variable "project" {
  type        = string
  sensitive   = true
  description = "Project"
}

variable "azure_subscription_id" {
  type        = string
  sensitive   = true
  description = "Azure Subscription ID"
}

variable "azure_client_id" {
  type        = string
  sensitive   = true
  description = "Azure Client ID"
}

variable "azure_client_secret" {
  type        = string
  sensitive   = true
  description = "Azure Client Secret"
}

variable "azure_tenant_id" {
  type        = string
  sensitive   = true
  description = "Azure Tenant ID"
}

variable "azure_location" {
  type        = string
  sensitive   = true
  description = "Azure Location"
}

variable "key_vault_resource_group" {
  type        = string
  sensitive   = true
  description = "Key Vault Resource Group"
}

variable "key_vault_name" {
  type        = string
  sensitive   = true
  description = "Key Vault Name"
}

variable "gcp_project" {
  type        = string
  sensitive   = true
  description = "GCP Project"
}

variable "gcp_region" {
  type        = string
  sensitive   = true
  description = "GCP Region"
}