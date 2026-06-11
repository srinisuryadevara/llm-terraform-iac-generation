# AWS Secrets Manager
provider "aws" {
  region = var.aws_region
}

resource "aws_secretsmanager_secret" "example" {
  name        = var.secret_name
  description = var.secret_description
  tags = {
    Environment = var.environment
    Project     = var.project
  }
}

resource "aws_secretsmanager_secret_version" "example" {
  secret_id     = aws_secretsmanager_secret.example.id
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

resource "azurerm_resource_group" "example" {
  name     = var.resource_group_name
  location = var.azure_location
  tags = {
    Environment = var.environment
    Project     = var.project
  }
}

resource "azurerm_key_vault" "example" {
  name                        = var.key_vault_name
  location                    = azurerm_resource_group.example.location
  resource_group_name         = azurerm_resource_group.example.name
  tenant_id                   = var.azure_tenant_id
  sku_name                    = "standard"
  soft_delete_retention_days  = 7
  enable_rbac_authorization  = true
  enabled_for_disk_encryption = true
  tags = {
    Environment = var.environment
    Project     = var.project
  }
}

resource "azurerm_key_vault_secret" "example" {
  name         = var.secret_name
  value        = var.secret_value
  key_vault_id = azurerm_key_vault.example.id
}

# GCP Secret Manager
provider "google" {
  project = var.gcp_project
  region  = var.gcp_region
}

resource "google_secretmanager_secret" "example" {
  secret_id = var.secret_name
  replication {
    automatic = true
  }
  labels = {
    Environment = var.environment
    Project     = var.project
  }
}

resource "google_secretmanager_secret_version" "example" {
  secret      = google_secretmanager_secret.example.id
  secret_data = var.secret_value
}

# Variables
variable "aws_region" {
  type        = string
  description = "AWS Region"
}

variable "secret_name" {
  type        = string
  description = "Secret Name"
}

variable "secret_description" {
  type        = string
  description = "Secret Description"
}

variable "secret_value" {
  type        = string
  sensitive   = true
  description = "Secret Value"
}

variable "environment" {
  type        = string
  description = "Environment"
}

variable "project" {
  type        = string
  description = "Project"
}

variable "azure_subscription_id" {
  type        = string
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
  description = "Azure Tenant ID"
}

variable "resource_group_name" {
  type        = string
  description = "Resource Group Name"
}

variable "azure_location" {
  type        = string
  description = "Azure Location"
}

variable "key_vault_name" {
  type        = string
  description = "Key Vault Name"
}

variable "gcp_project" {
  type        = string
  description = "GCP Project"
}

variable "gcp_region" {
  type        = string
  description = "GCP Region"
}