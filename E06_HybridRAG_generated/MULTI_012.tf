# Configure the AWS Provider
provider "aws" {
  region = var.aws_region
}

# Configure the Azure Provider
provider "azurerm" {
  version = "~>3.47.0"
  features {}
}

# Configure the Google Cloud Provider
provider "google" {
  project = var.gcp_project
  region  = var.gcp_region
}

# Variables
variable "aws_region" {
  type        = string
  description = "AWS Region"
}

variable "gcp_project" {
  type        = string
  description = "GCP Project"
}

variable "gcp_region" {
  type        = string
  description = "GCP Region"
}

variable "azure_subscription_id" {
  type        = string
  description = "Azure Subscription ID"
}

variable "azure_tenant_id" {
  type        = string
  description = "Azure Tenant ID"
}

variable "secret_name" {
  type        = string
  description = "Secret Name"
}

variable "secret_value" {
  type        = string
  description = "Secret Value"
  sensitive   = true
}

# AWS Secrets Manager
resource "aws_secretsmanager_secret" "example" {
  name = var.secret_name
}

resource "aws_secretsmanager_secret_version" "example" {
  secret_id     = aws_secretsmanager_secret.example.id
  secret_string = var.secret_value
}

# Azure Key Vault
data "azurerm_client_config" "current" {}

resource "azurerm_resource_group" "example" {
  name     = "example-resource-group"
  location = "West US"
}

resource "azurerm_key_vault" "example" {
  name                        = "example-key-vault"
  location                    = azurerm_resource_group.example.location
  resource_group_name         = azurerm_resource_group.example.name
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  sku_name                    = "standard"
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false
  enabled_for_disk_encryption = true
}

resource "azurerm_key_vault_secret" "example" {
  name         = var.secret_name
  value        = var.secret_value
  key_vault_id = azurerm_key_vault.example.id
}

# GCP Secret Manager
resource "google_secret_manager_secret" "example" {
  secret_id = var.secret_name
}

resource "google_secret_manager_secret_version" "example" {
  secret      = google_secret_manager_secret.example.id
  secret_data = var.secret_value
}

output "aws_secret_arn" {
  value       = aws_secretsmanager_secret.example.arn
  description = "AWS Secret ARN"
}

output "azure_key_vault_id" {
  value       = azurerm_key_vault.example.id
  description = "Azure Key Vault ID"
}

output "gcp_secret_id" {
  value       = google_secret_manager_secret.example.id
  description = "GCP Secret ID"
}