# AWS Secrets Manager
provider "aws" {
  region = var.aws_region
}

resource "aws_secretsmanager_secret" "example" {
  name = var.secret_name
}

resource "aws_secretsmanager_secret_version" "example" {
  secret_id     = aws_secretsmanager_secret.example.id
  secret_string = var.secret_value
}

# Azure Key Vault
provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "example" {
  name     = var.resource_group_name
  location = var.azure_location
}

resource "azurerm_key_vault" "example" {
  name                        = var.key_vault_name
  resource_group_name         = azurerm_resource_group.example.name
  location                    = azurerm_resource_group.example.location
  tenant_id                   = var.azure_tenant_id
  sku_name                    = "standard"
  soft_delete_retention_days  = 7
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

variable "secret_value" {
  type        = string
  sensitive   = true
  description = "Secret Value"
}

variable "resource_group_name" {
  type        = string
  description = "Azure Resource Group Name"
}

variable "azure_location" {
  type        = string
  description = "Azure Location"
}

variable "key_vault_name" {
  type        = string
  description = "Azure Key Vault Name"
}

variable "azure_tenant_id" {
  type        = string
  sensitive   = true
  description = "Azure Tenant ID"
}

variable "gcp_project" {
  type        = string
  description = "GCP Project"
}

variable "gcp_region" {
  type        = string
  description = "GCP Region"
}