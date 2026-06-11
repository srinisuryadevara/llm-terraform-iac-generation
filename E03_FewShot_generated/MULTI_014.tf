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

# Create AWS S3 Bucket
resource "aws_s3_bucket" "aws_bucket" {
  bucket = var.aws_bucket_name
  acl    = "private"

  versioning {
    enabled = true
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

# Create Azure Storage Account
resource "azurerm_storage_account" "azure_storage" {
  name                     = var.azure_storage_name
  resource_group_name      = var.azure_resource_group
  location                 = var.azure_location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = {
    environment = "production"
  }
}

# Create GCP Cloud Storage Bucket
resource "google_storage_bucket" "gcp_bucket" {
  name     = var.gcp_bucket_name
  location = var.gcp_location
  storage_class = "REGIONAL"

  versioning {
    enabled = true
  }
}

variable "aws_region" {
  type        = string
  sensitive   = true
}

variable "aws_bucket_name" {
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

variable "azure_storage_name" {
  type        = string
  sensitive   = true
}

variable "azure_resource_group" {
  type        = string
  sensitive   = true
}

variable "azure_location" {
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

variable "gcp_bucket_name" {
  type        = string
  sensitive   = true
}

variable "gcp_location" {
  type        = string
  sensitive   = true
}