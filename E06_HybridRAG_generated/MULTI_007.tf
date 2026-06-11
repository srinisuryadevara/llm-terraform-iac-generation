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

variable "aws_secret_name" {
  type        = string
  description = "AWS Secret Name"
}

variable "aws_secret_value" {
  type        = string
  sensitive   = true
  description = "AWS Secret Value"
}

variable "azure_subscription_id" {
  type        = string
  description = "Azure Subscription ID"
}

variable "azure_resource_group_name" {
  type        = string
  description = "Azure Resource Group Name"
}

variable "azure_key_vault_name" {
  type        = string
  description = "Azure Key Vault Name"
}

variable "azure_secret_name" {
  type        = string
  description = "Azure Secret Name"
}

variable "azure_secret_value" {
  type        = string
  sensitive   = true
  description = "Azure Secret Value"
}

variable "gcp_project" {
  type        = string
  description = "GCP Project"
}

variable "gcp_region" {
  type        = string
  description = "GCP Region"
}

variable "gcp_secret_name" {
  type        = string
  description = "GCP Secret Name"
}

variable "gcp_secret_value" {
  type        = string
  sensitive   = true
  description = "GCP Secret Value"
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
data "azurerm_client_config" "current" {}

resource "azurerm_resource_group" "example" {
  name     = var.azure_resource_group_name
  location = "West US"
}

resource "azurerm_key_vault" "example" {
  name                        = var.azure_key_vault_name
  location                    = azurerm_resource_group.example.location
  resource_group_name         = azurerm_resource_group.example.name
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  sku_name                    = "standard"
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false
}

resource "azurerm_key_vault_secret" "example" {
  name         = var.azure_secret_name
  value        = var.azure_secret_value
  key_vault_id = azurerm_key_vault.example.id
}

# GCP Secret Manager
resource "google_secret_manager_secret" "example" {
  secret_id = var.gcp_secret_name
}

resource "google_secret_manager_secret_version" "example" {
  secret      = google_secret_manager_secret.example.id
  secret_data = var.gcp_secret_value
}