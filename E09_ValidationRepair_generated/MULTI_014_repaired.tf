# Configure the AWS Provider
provider "aws" {
  region = var.aws_region
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}

# Create an S3 bucket
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

  tags = {
    Environment = "dev"
    Project     = "object-storage"
    Owner       = "your-name"
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

# Create a resource group
resource "azurerm_resource_group" "azure_rg" {
  name     = var.azure_resource_group_name
  location = var.azure_location

  tags = {
    Environment = "dev"
    Project     = "object-storage"
    Owner       = "your-name"
  }
}

# Create a storage account
resource "azurerm_storage_account" "azure_sa" {
  name                     = var.azure_storage_account_name
  resource_group_name      = azurerm_resource_group.azure_rg.name
  location                 = azurerm_resource_group.azure_rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"

  depends_on = [
    azurerm_resource_group.azure_rg
  ]

  tags = {
    Environment = "dev"
    Project     = "object-storage"
    Owner       = "your-name"
  }
}

# Configure the Google Cloud Provider
provider "google" {
  project = var.gcp_project_id
  region  = var.gcp_region
  credentials = var.gcp_credentials
}

# Create a storage bucket
resource "google_storage_bucket" "gcp_bucket" {
  name     = var.gcp_bucket_name
  location = var.gcp_location
  storage_class = "REGIONAL"

  labels = {
    Environment = "dev"
    Project     = "object-storage"
    Owner       = "your-name"
  }
}

# Output the bucket names
output "aws_bucket_name" {
  value = aws_s3_bucket.aws_bucket.id
}

output "azure_storage_account_name" {
  value = azurerm_storage_account.azure_sa.name
}

output "gcp_bucket_name" {
  value = google_storage_bucket.gcp_bucket.name
}