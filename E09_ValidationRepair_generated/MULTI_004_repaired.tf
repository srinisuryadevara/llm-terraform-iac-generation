# Configure the AWS Provider
provider "aws" {
  region = var.aws_region
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}

# Create S3 Bucket
resource "aws_s3_bucket" "aws_bucket" {
  bucket = var.aws_bucket_name
  acl    = var.aws_bucket_acl

  versioning {
    enabled = var.aws_bucket_versioning
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = var.aws_bucket_sse_algorithm
      }
    }
  }
}

# Configure the Azure Provider
provider "azurerm" {
  features {}
  subscription_id = var.azure_subscription_id
  client_id       = var.azure_client_id
  client_secret   = var.azure_client_secret
  tenant_id       = var.azure_tenant_id
}

# Create Azure Storage Account
resource "azurerm_storage_account" "azure_storage" {
  name                     = var.azure_storage_name
  resource_group_name      = var.azure_resource_group_name
  location                 = var.azure_location
  account_tier             = var.azure_storage_tier
  account_replication_type = var.azure_storage_replication

  tags = {
    environment = var.azure_environment
  }
}

# Configure the GCP Provider
provider "google" {
  project = var.gcp_project
  region  = var.gcp_region
  credentials = var.gcp_credentials
}

# Create GCP Cloud Storage Bucket
resource "google_storage_bucket" "gcp_bucket" {
  name                        = var.gcp_bucket_name
  location                    = var.gcp_location
  storage_class               = var.gcp_storage_class
  uniform_bucket_level_access = var.gcp_uniform_bucket_access

  versioning {
    enabled = var.gcp_bucket_versioning
  }
}

variable "aws_region" {
  type = string
}

variable "aws_access_key" {
  type = string
  sensitive = true
}

variable "aws_secret_key" {
  type = string
  sensitive = true
}

variable "aws_bucket_name" {
  type = string
}

variable "aws_bucket_acl" {
  type = string
}

variable "aws_bucket_versioning" {
  type = bool
}

variable "aws_bucket_sse_algorithm" {
  type = string
}

variable "azure_subscription_id" {
  type = string
  sensitive = true
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
  sensitive = true
}

variable "azure_storage_name" {
  type = string
}

variable "azure_resource_group_name" {
  type = string
}

variable "azure_location" {
  type = string
}

variable "azure_storage_tier" {
  type = string
}

variable "azure_storage_replication" {
  type = string
}

variable "azure_environment" {
  type = string
}

variable "gcp_project" {
  type = string
}

variable "gcp_region" {
  type = string
}

variable "gcp_credentials" {
  type = string
  sensitive = true
}

variable "gcp_bucket_name" {
  type = string
}

variable "gcp_location" {
  type = string
}

variable "gcp_storage_class" {
  type = string
}

variable "gcp_uniform_bucket_access" {
  type = bool
}

variable "gcp_bucket_versioning" {
  type = bool
}

output "aws_s3_bucket_id" {
  value = aws_s3_bucket.aws_bucket.id
}

output "aws_s3_bucket_arn" {
  value = aws_s3_bucket.aws_bucket.arn
}

output "azure_storage_account_id" {
  value = azurerm_storage_account.azure_storage.id
}

output "azure_storage_account_name" {
  value = azurerm_storage_account.azure_storage.name
}

output "gcp_cloud_storage_bucket_name" {
  value = google_storage_bucket.gcp_bucket.name
}

output "gcp_cloud_storage_bucket_self_link" {
  value = google_storage_bucket.gcp_bucket.self_link
}