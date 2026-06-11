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
  type        = string
  description = "AWS Region"
}

variable "azure_subscription_id" {
  type        = string
  description = "Azure Subscription ID"
}

variable "azure_client_id" {
  type        = string
  description = "Azure Client ID"
}

variable "azure_client_secret" {
  type        = string
  description = "Azure Client Secret"
}

variable "azure_tenant_id" {
  type        = string
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

variable "bucket_name_aws" {
  type        = string
  description = "AWS S3 Bucket Name"
}

variable "bucket_name_azure" {
  type        = string
  description = "Azure Storage Account Name"
}

variable "bucket_name_gcp" {
  type        = string
  description = "GCP Cloud Storage Bucket Name"
}

resource "aws_s3_bucket" "aws_bucket" {
  bucket = var.bucket_name_aws
  acl    = "private"
  versioning {
    enabled = true
  }
  force_destroy = true
  tags = {
    Name        = var.bucket_name_aws
    Environment = "aws"
  }
}

resource "azurerm_storage_account" "azure_storage" {
  name                     = var.bucket_name_azure
  resource_group_name      = var.azure_resource_group
  location                 = var.azure_location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "google_storage_bucket" "gcp_bucket" {
  name     = var.bucket_name_gcp
  location = var.gcp_region
  storage_class = "REGIONAL"
}

variable "azure_resource_group" {
  type        = string
  description = "Azure Resource Group"
}

variable "azure_location" {
  type        = string
  description = "Azure Location"
}

output "aws_bucket_name" {
  value = aws_s3_bucket.aws_bucket.id
}

output "azure_storage_account_name" {
  value = azurerm_storage_account.azure_storage.name
}

output "gcp_bucket_name" {
  value = google_storage_bucket.gcp_bucket.name
}