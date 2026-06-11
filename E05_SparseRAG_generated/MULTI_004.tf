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
}

# Create GCP Cloud Storage Bucket
resource "google_storage_bucket" "gcp_object_storage" {
  name          = var.gcp_bucket_name
  location      = var.gcp_location
  project       = var.gcp_project
  storage_class = "STANDARD"
}

# Create Azure Storage Container
resource "azurerm_storage_container" "azure_container" {
  name                  = var.azure_container_name
  storage_account_name  = azurerm_storage_account.azure_object_storage.name
  container_access_type = "private"
}

# Create GCP Cloud Storage Bucket IAM Policy
resource "google_storage_bucket_iam_policy" "gcp_policy" {
  bucket      = google_storage_bucket.gcp_object_storage.name
  policy_data = data.google_iam_policy.admin.policy_data
}

data "google_iam_policy" "admin" {
  binding {
    role = "roles/storage.admin"

    members = [
      "serviceAccount:${google_service_account.storage.email}",
    ]
  }
}

# Create GCP Service Account
resource "google_service_account" "storage" {
  account_id   = "svc-webserver-storage"
  display_name = "Webserver Storage SA"
}

# Create GCP IAM Member
resource "google_project_iam_member" "storage" {
  project = var.gcp_project
  role    = "roles/storage.admin"
  member  = "serviceAccount:${google_service_account.storage.email}"
}

variable "aws_region" {
  type        = string
  description = "AWS Region"
}

variable "aws_bucket_name" {
  type        = string
  description = "AWS S3 Bucket Name"
}

variable "azure_storage_account_name" {
  type        = string
  description = "Azure Storage Account Name"
}

variable "azure_resource_group_name" {
  type        = string
  description = "Azure Resource Group Name"
}

variable "azure_location" {
  type        = string
  description = "Azure Location"
}

variable "azure_container_name" {
  type        = string
  description = "Azure Container Name"
}

variable "gcp_project" {
  type        = string
  description = "GCP Project"
}

variable "gcp_region" {
  type        = string
  description = "GCP Region"
}

variable "gcp_bucket_name" {
  type        = string
  description = "GCP Cloud Storage Bucket Name"
}

variable "gcp_location" {
  type        = string
  description = "GCP Location"
}