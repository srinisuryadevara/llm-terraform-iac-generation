# Configure the AWS Provider
provider "aws" {
  region = var.aws_region
}

# Configure the Azure Provider
provider "azurerm" {
  version = "~> 2.0"
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

variable "gcp_project" {
  type        = string
  description = "GCP Project"
}

variable "gcp_region" {
  type        = string
  description = "GCP Region"
}

variable "resource_group_name" {
  type        = string
  description = "Azure Resource Group Name"
}

variable "storage_account_name" {
  type        = string
  description = "Azure Storage Account Name"
}

variable "bucket_name_aws" {
  type        = string
  description = "AWS S3 Bucket Name"
}

variable "bucket_name_gcp" {
  type        = string
  description = "GCP Cloud Storage Bucket Name"
}

# Create AWS S3 Bucket
resource "aws_s3_bucket" "aws_bucket" {
  bucket = var.bucket_name_aws
  acl    = "private"

  tags = {
    Name        = var.bucket_name_aws
    Environment = "dev"
  }
}

# Create Azure Storage Account and Container
resource "azurerm_resource_group" "example" {
  name     = var.resource_group_name
  location = "West US"
}

resource "azurerm_storage_account" "example" {
  name                     = var.storage_account_name
  resource_group_name      = azurerm_resource_group.example.name
  location                 = azurerm_resource_group.example.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = {
    environment = "dev"
  }
}

resource "azurerm_storage_container" "example" {
  name                  = "example-container"
  storage_account_name  = azurerm_storage_account.example.name
  container_access_type = "private"
}

# Create GCP Cloud Storage Bucket
resource "google_storage_bucket" "gcp_bucket" {
  name     = var.bucket_name_gcp
  location = var.gcp_region

  uniform_bucket_level_access = true

  lifecycle_rule {
    condition {
      age = 365
    }
    action {
      type = "Delete"
    }
  }
}

output "aws_bucket_name" {
  value = aws_s3_bucket.aws_bucket.id
}

output "azure_storage_account_name" {
  value = azurerm_storage_account.example.name
}

output "gcp_bucket_name" {
  value = google_storage_bucket.gcp_bucket.name
}