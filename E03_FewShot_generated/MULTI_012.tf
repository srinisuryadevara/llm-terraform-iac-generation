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

# AWS Secrets Manager
resource "aws_secretsmanager_secret" "example" {
  name = var.aws_secret_name
}

resource "aws_secretsmanager_secret_version" "example" {
  secret_id     = aws_secretsmanager_secret.example.id
  secret_string = var.aws_secret_value
}

# Azure Key Vault
resource "azurerm_resource_group" "example" {
  name     = var.azure_resource_group_name
  location = var.azure_location
}

resource "azurerm_key_vault" "example" {
  name                        = var.azure_key_vault_name
  location                    = azurerm_resource_group.example.location
  resource_group_name         = azurerm_resource_group.example.name
  tenant_id                   = var.azure_tenant_id
  sku_name                    = "standard"
  soft_delete_retention_days  = 7
}

resource "azurerm_key_vault_secret" "example" {
  name         = var.azure_secret_name
  value        = var.azure_secret_value
  key_vault_id = azurerm_key_vault.example.id
}

# GCP Secret Manager
resource "google_secretmanager_secret" "example" {
  secret_id = var.gcp_secret_name
}

resource "google_secretmanager_secret_version" "example" {
  secret      = google_secretmanager_secret.example.id
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