# Configure the AWS Provider
provider "aws" {
  region = var.aws_region
}

# Configure the Azure Provider
provider "azurerm" {
  features {}
}

# Configure the Google Cloud Provider
provider "google" {
  project = var.google_project
  region  = var.google_region
}

# Create AWS S3 Bucket
resource "aws_s3_bucket" "aws_object_storage" {
  bucket = var.aws_bucket_name

  lifecycle {
    prevent_destroy = true
  }

  tags = {
    Name = var.aws_bucket_name
  }
}

# Create Azure Storage Account
resource "azurerm_storage_account" "azure_object_storage" {
  name                     = var.azure_storage_account_name
  resource_group_name      = var.azure_resource_group_name
  location                 = var.azure_location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = {
    environment = var.environment
  }
}

# Create GCP Cloud Storage Bucket
resource "google_storage_bucket" "gcp_object_storage" {
  name          = var.gcp_bucket_name
  location      = var.gcp_location
  project       = var.google_project
  storage_class = "STANDARD"
}

# Create Azure Storage Container
resource "azurerm_storage_container" "azure_container" {
  name                  = var.azure_container_name
  storage_account_name  = azurerm_storage_account.azure_object_storage.name
  container_access_type = "private"
}

# Create GCP Cloud Storage Bucket Public Access Block
resource "google_storage_bucket_iam_binding" "gcp_bucket_iam_binding" {
  bucket = google_storage_bucket.gcp_object_storage.name
  role   = "roles/storage.objectViewer"
  members = [
    "allUsers",
  ]
}

# Create AWS S3 Bucket Public Access Block
resource "aws_s3_bucket_public_access_block" "aws_public_access" {
  bucket = aws_s3_bucket.aws_object_storage.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

variable "aws_region" {
  type = string
}

variable "aws_bucket_name" {
  type = string
}

variable "azure_storage_account_name" {
  type = string
}

variable "azure_resource_group_name" {
  type = string
}

variable "azure_location" {
  type = string
}

variable "azure_container_name" {
  type = string
}

variable "gcp_bucket_name" {
  type = string
}

variable "gcp_location" {
  type = string
}

variable "google_project" {
  type = string
}

variable "google_region" {
  type = string
}

variable "environment" {
  type = string
}