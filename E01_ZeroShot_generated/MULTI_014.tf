# Configure the AWS Provider
provider "aws" {
  region = var.aws_region
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
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

# Configure the Azure Provider
provider "azurerm" {
  features {}
  subscription_id = var.azure_subscription_id
  client_id      = var.azure_client_id
  client_secret = var.azure_client_secret
  tenant_id      = var.azure_tenant_id
}

# Create Azure Storage Account
resource "azurerm_storage_account" "azure_storage" {
  name                     = var.azure_storage_name
  resource_group_name      = var.azure_resource_group_name
  location                 = var.azure_location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = {
    environment = "production"
  }
}

# Create Azure Storage Container
resource "azurerm_storage_container" "azure_container" {
  name                  = var.azure_container_name
  storage_account_name  = azurerm_storage_account.azure_storage.name
  container_access_type = "private"
}

# Configure the Google Cloud Provider
provider "google" {
  project = var.gcp_project_id
  region  = var.gcp_region
  credentials = var.gcp_credentials
}

# Create GCP Storage Bucket
resource "google_storage_bucket" "gcp_bucket" {
  name     = var.gcp_bucket_name
  location = var.gcp_location
  storage_class = "REGIONAL"

  versioning {
    enabled = true
  }
}

# Output the created bucket names
output "aws_bucket_name" {
  value = aws_s3_bucket.aws_bucket.id
}

output "azure_storage_name" {
  value = azurerm_storage_account.azure_storage.name
}

output "gcp_bucket_name" {
  value = google_storage_bucket.gcp_bucket.name
}