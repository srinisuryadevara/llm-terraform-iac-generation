terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 2.0"
    }
    google = {
      source  = "hashicorp/google"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

provider "azurerm" {
  features {}
  subscription_id = var.azure_subscription_id
  client_id       = var.azure_client_id
  client_secret   = var.azure_client_secret
  tenant_id       = var.azure_tenant_id
}

provider "google" {
  project = var.gcp_project
  region  = var.gcp_region
}

variable "aws_region" {
  type = string
}

variable "azure_subscription_id" {
  type = string
}

variable "azure_client_id" {
  type = string
}

variable "azure_client_secret" {
  type = string
}

variable "azure_tenant_id" {
  type = string
}

variable "gcp_project" {
  type = string
}

variable "gcp_region" {
  type = string
}

variable "bucket_name_aws" {
  type = string
}

variable "bucket_name_azure" {
  type = string
}

variable "bucket_name_gcp" {
  type = string
}

resource "aws_s3_bucket" "data" {
  bucket = var.bucket_name_aws
  acl    = "private"
  force_destroy = true
  tags = {
    Name        = "data"
    Environment = "env"
  }
}

resource "azurerm_storage_account" "data" {
  name                     = var.bucket_name_azure
  resource_group_name      = "example-resources"
  location                 = "West US"
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_container" "data" {
  name                     = "data"
  storage_account_name      = azurerm_storage_account.data.name
  container_access_type     = "private"
  depends_on               = [azurerm_storage_account.data]
}

resource "google_storage_bucket" "data" {
  name     = var.bucket_name_gcp
  location = var.gcp_region
  storage_class = "REGIONAL"
}

output "aws_bucket_name" {
  value = aws_s3_bucket.data.id
}

output "azure_bucket_name" {
  value = azurerm_storage_account.data.name
}

output "gcp_bucket_name" {
  value = google_storage_bucket.data.name
}