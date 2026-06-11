# Configure the AWS Provider
provider "aws" {
  region = var.aws_region
}

# Configure the Azure Provider
provider "azurerm" {
  features {}
}

# Configure the GCP Provider
provider "google" {
  project = var.gcp_project
  region  = var.gcp_region
}

# Create AWS Secrets Manager secret
resource "aws_secretsmanager_secret" "aws_secret" {
  name = var.aws_secret_name
}

resource "aws_secretsmanager_secret_version" "aws_secret_version" {
  secret_id     = aws_secretsmanager_secret.aws_secret.id
  secret_string = var.aws_secret_value
}

# Create Azure Key Vault
resource "azurerm_resource_group" "azure_rg" {
  name     = var.azure_rg_name
  location = var.azure_location
}

resource "azurerm_key_vault" "azure_kv" {
  name                        = var.azure_kv_name
  resource_group_name         = azurerm_resource_group.azure_rg.name
  location                    = azurerm_resource_group.azure_rg.location
  tenant_id                   = var.azure_tenant_id
  sku_name                    = "standard"
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false
}

resource "azurerm_key_vault_secret" "azure_secret" {
  name         = var.azure_secret_name
  value        = var.azure_secret_value
  key_vault_id = azurerm_key_vault.azure_kv.id
}

# Create GCP Secret Manager secret
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

variable "azure_rg_name" {
  type        = string
  sensitive   = true
}

variable "azure_location" {
  type        = string
  sensitive   = true
}

variable "azure_kv_name" {
  type        = string
  sensitive   = true
}

variable "azure_tenant_id" {
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