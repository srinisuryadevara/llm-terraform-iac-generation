terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.47.0"
    }
    google = {
      source  = "hashicorp/google"
      version = "~> 4.0"
    }
  }
}

# AWS Secrets Manager
provider "aws" {
  region = var.aws_region
}

variable "aws_region" {
  default = "us-west-2"
}

variable "aws_secret_name" {
  type = string
}

variable "aws_secret_value" {
  type      = string
  sensitive = true
}

resource "aws_secretsmanager_secret" "secret" {
  name = var.aws_secret_name
}

resource "aws_secretsmanager_secret_version" "secret_version" {
  secret_id     = aws_secretsmanager_secret.secret.id
  secret_string = var.aws_secret_value
}

# Azure Key Vault
provider "azurerm" {
  features {}
}

variable "azure_location" {
  type = string
}

variable "azure_resource_group_name" {
  type = string
}

variable "azure_key_vault_name" {
  type = string
}

variable "azure_secret_name" {
  type = string
}

variable "azure_secret_value" {
  type      = string
  sensitive = true
}

resource "azurerm_resource_group" "resource_group" {
  name     = var.azure_resource_group_name
  location = var.azure_location
}

resource "azurerm_key_vault" "key_vault" {
  name                        = var.azure_key_vault_name
  location                    = azurerm_resource_group.resource_group.location
  resource_group_name         = azurerm_resource_group.resource_group.name
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  sku_name                    = "standard"
  purge_protection_enabled    = false
}

resource "azurerm_key_vault_secret" "secret" {
  name         = var.azure_secret_name
  value        = var.azure_secret_value
  key_vault_id = azurerm_key_vault.key_vault.id
}

data "azurerm_client_config" "current" {}

# GCP Secret Manager
provider "google" {
  project = var.gcp_project_id
  region  = var.gcp_region
}

variable "gcp_project_id" {
  type = string
}

variable "gcp_region" {
  type = string
}

variable "gcp_secret_name" {
  type = string
}

variable "gcp_secret_value" {
  type      = string
  sensitive = true
}

resource "google_secret_manager_secret" "secret" {
  secret_id = var.gcp_secret_name
}

resource "google_secret_manager_secret_version" "secret_version" {
  secret      = google_secret_manager_secret.secret.id
  secret_data = var.gcp_secret_value
}