# Configure the AWS Provider
provider "aws" {
  region = var.aws_region
}

# Configure the Azure Provider
provider "azurerm" {
  features {}
  subscription_id = var.azure_subscription_id
  client_id      = var.azure_client_id
  client_secret = var.azure_client_secret
  tenant_id      = var.azure_tenant_id
}

# Configure the GCP Provider
provider "google" {
  project = var.gcp_project
  region  = var.gcp_region
}

# Create AWS Secrets Manager Secret
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
  tenant_id                  = var.azure_tenant_id
  sku_name                    = "standard"
  soft_delete_retention_days = 7
}

resource "azurerm_key_vault_secret" "azure_secret" {
  name         = var.azure_secret_name
  value        = var.azure_secret_value
  key_vault_id = azurerm_key_vault.azure_kv.id
}

# Create GCP Secret Manager Secret
resource "google_secret_manager_secret" "gcp_secret" {
  secret_id = var.gcp_secret_name
}

resource "google_secret_manager_secret_version" "gcp_secret_version" {
  secret      = google_secret_manager_secret.gcp_secret.id
  secret_data = var.gcp_secret_value
}

variable "aws_region" {
  type = string
}

variable "aws_secret_name" {
  type = string
}

variable "aws_secret_value" {
  type = string
  sensitive = true
}

variable "azure_subscription_id" {
  type = string
}

variable "azure_client_id" {
  type = string
  sensitive = true
}

variable "azure_client_secret" {
  type = string
  sensitive = true
}

variable "azure_tenant_id" {
  type = string
}

variable "azure_rg_name" {
  type = string
}

variable "azure_location" {
  type = string
}

variable "azure_kv_name" {
  type = string
}

variable "azure_secret_name" {
  type = string
}

variable "azure_secret_value" {
  type = string
  sensitive = true
}

variable "gcp_project" {
  type = string
}

variable "gcp_region" {
  type = string
}

variable "gcp_secret_name" {
  type = string
}

variable "gcp_secret_value" {
  type = string
  sensitive = true
}