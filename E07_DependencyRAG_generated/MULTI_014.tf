# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
}

# Create an AWS S3 Bucket
resource "aws_s3_bucket" "aws_bucket" {
  bucket        = "aws-bucket"
  force_destroy = true
  tags = {
    Name        = "aws-bucket"
    Environment = "aws"
  }
}

# Create an object in the AWS S3 Bucket
resource "aws_s3_bucket_object" "aws_object" {
  bucket = aws_s3_bucket.aws_bucket.id
  key    = "aws-object.txt"
  source = "resources/aws-object.txt"
  tags = {
    Name        = "aws-object"
    Environment = "aws"
  }
}

# Configure the Azure Provider
provider "azurerm" {
  features {}
}

# Create a resource group for Azure
resource "azurerm_resource_group" "azure_group" {
  name     = "azure-group"
  location = "East US"
}

# Create an Azure Storage Account
resource "azurerm_storage_account" "azure_account" {
  name                     = "azureaccount"
  resource_group_name      = azurerm_resource_group.azure_group.name
  location                 = azurerm_resource_group.azure_group.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# Create a container in the Azure Storage Account
resource "azurerm_storage_container" "azure_container" {
  name                  = "azure-container"
  storage_account_name  = azurerm_storage_account.azure_account.name
  container_access_type = "private"
}

# Create a blob in the Azure container
resource "azurerm_storage_blob" "azure_blob" {
  name                   = "azure-blob.txt"
  resource_group_name    = azurerm_resource_group.azure_group.name
  storage_account_name   = azurerm_storage_account.azure_account.name
  storage_container_name = azurerm_storage_container.azure_container.name
  type                   = "Block"
}

# Configure the Google Cloud Provider
provider "google" {
  project = "your-project-id"
  region  = "us-central1"
}

# Create a Google Cloud Storage Bucket
resource "google_storage_bucket" "gcp_bucket" {
  name     = "gcp-bucket"
  location = "US"
}

# Create an object in the Google Cloud Storage Bucket
resource "google_storage_bucket_object" "gcp_object" {
  name   = "gcp-object.txt"
  bucket = google_storage_bucket.gcp_bucket.name
  source = "resources/gcp-object.txt"
}

output "aws_bucket_name" {
  value = aws_s3_bucket.aws_bucket.id
}

output "azure_container_name" {
  value = azurerm_storage_container.azure_container.name
}

output "gcp_bucket_name" {
  value = google_storage_bucket.gcp_bucket.name
}