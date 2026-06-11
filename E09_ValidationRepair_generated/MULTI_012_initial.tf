# Configure the AWS Provider
provider "aws" {
  region = var.aws_region
}

# Configure the Azure Provider
provider "azurerm" {
  features {}
  subscription_id = var.azure_subscription_id
  client_id       = var.azure_client_id
  client_secret   = var.azure_client_secret
  tenant_id       = var.azure_tenant_id
}

# Configure the GCP Provider
provider "google" {
  project = var.gcp_project
  region  = var.gcp_region
}

# Create a secret in AWS Secrets Manager
resource "aws_secretsmanager_secret" "aws_secret" {
  name = var.aws_secret_name
}

resource "aws_secretsmanager_secret_version" "aws_secret_version" {
  secret_id     = aws_secretsmanager_secret.aws_secret.id
  secret_string = var.aws_secret_value
}

# Create a secret in Azure Key Vault
resource "azurerm_key_vault" "azure_key_vault" {
  name                        = var.azure_key_vault_name
  location                    = var.azure_location
  resource_group_name         = var.azure_resource_group_name
  sku_name                    = "standard"
  tenant_id                   = var.azure_tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false
}

resource "azurerm_key_vault_secret" "azure_secret" {
  name         = var.azure_secret_name
  value        = var.azure_secret_value
  key_vault_id = azurerm_key_vault.azure_key_vault.id
}

# Create a secret in GCP Secret Manager
resource "google_secretmanager_secret" "gcp_secret" {
  secret_id = var.gcp_secret_name
}

resource "google_secretmanager_secret_version" "gcp_secret_version" {
  secret      = google_secretmanager_secret.gcp_secret.id
  secret_data = var.gcp_secret_value
}

variable "aws_region" {
  type        = string
  sensitive   = true
}

variable "aws_secret_name" {
  type        = string
  sensitive   = true
}

variable "aws_secret_value" {
  type        = string
  sensitive   = true
}

variable "azure_subscription_id" {
  type        = string
  sensitive   = true
}

variable "azure_client_id" {
  type        = string
  sensitive   = true
}

variable "azure_client_secret" {
  type        = string
  sensitive   = true
}

variable "azure_tenant_id" {
  type        = string
  sensitive   = true
}

variable "azure_location" {
  type        = string
  sensitive   = true
}

variable "azure_resource_group_name" {
  type        = string
  sensitive   = true
}

variable "azure_key_vault_name" {
  type        = string
  sensitive   = true
}

variable "azure_secret_name" {
  type        = string
  sensitive   = true
}

variable "azure_secret_value" {
  type        = string
  sensitive   = true
}

variable "gcp_project" {
  type        = string
  sensitive   = true
}

variable "gcp_region" {
  type        = string
  sensitive   = true
}

variable "gcp_secret_name" {
  type        = string
  sensitive   = true
}

variable "gcp_secret_value" {
  type        = string
  sensitive   = true
}