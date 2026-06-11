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
  project = var.gcp_project
  region  = var.gcp_region
}

# Create S3 Bucket
resource "aws_s3_bucket" "s3_node" {
  bucket = var.s3_bucket_name

  lifecycle {
    prevent_destroy = true
  }

  tags = {
    Name = var.s3_bucket_name
  }
}

# Create Azure Storage Account
resource "azurerm_storage_account" "azure_storage" {
  name                     = var.azure_storage_name
  resource_group_name      = var.azure_resource_group_name
  location                 = var.azure_location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# Create GCP Cloud Storage Bucket
resource "google_storage_bucket" "gcp_bucket" {
  name          = var.gcp_bucket_name
  location      = var.gcp_location
  project       = var.gcp_project
  storage_class = "STANDARD"
}

# Create S3 Bucket Public Access Block
resource "aws_s3_bucket_public_access_block" "s3_public_access" {
  bucket                  = aws_s3_bucket.s3_node.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Create Azure Storage Container
resource "azurerm_storage_container" "azure_container" {
  name                  = var.azure_container_name
  storage_account_name  = azurerm_storage_account.azure_storage.name
  container_access_type = "private"
}

# Create GCP Cloud Storage Bucket IAM Policy
resource "google_storage_bucket_iam_policy" "gcp_bucket_policy" {
  bucket      = google_storage_bucket.gcp_bucket.name
  policy_data = jsonencode({
    "version" : "1",
    "bindings" : [
      {
        "role" : "roles/storage.admin",
        "members" : [
          "serviceAccount:${google_service_account.storage.email}",
        ]
      },
    ]
  })
}

# Create GCP Cloud Storage Service Account
resource "google_service_account" "storage" {
  account_id   = "svc-webserver-storage"
  display_name = "Webserver Storage SA"
}

# Create GCP Cloud Storage IAM Member
resource "google_project_iam_member" "storage" {
  project = var.gcp_project
  role    = "roles/storage.admin"
  member  = "serviceAccount:${google_service_account.storage.email}"
}

variable "aws_region" {
  type = string
}

variable "azure_location" {
  type = string
}

variable "azure_resource_group_name" {
  type = string
}

variable "azure_storage_name" {
  type = string
}

variable "gcp_project" {
  type = string
}

variable "gcp_region" {
  type = string
}

variable "gcp_location" {
  type = string
}

variable "gcp_bucket_name" {
  type = string
}

variable "s3_bucket_name" {
  type = string
}

variable "azure_container_name" {
  type = string
}