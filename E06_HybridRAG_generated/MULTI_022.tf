terraform {
  backend "local" {
    path = "./terraform.tfstate"
  }
}

# AWS S3
provider "aws" {
  region = "us-west-2"
}

variable "aws_bucket_name" {
  type        = string
  default     = "aws-object-storage"
}

resource "aws_s3_bucket" "aws_object_storage" {
  bucket = var.aws_bucket_name
  acl    = "private"

  versioning {
    enabled = true
  }

  tags = {
    Name        = "AWS Object Storage"
    Environment = "Dev"
  }
}

# Azure Storage Account
provider "azurerm" {
  version = "~> 2.0"
  features {}
}

variable "azure_resource_group_name" {
  type        = string
  default     = "azure-resource-group"
}

variable "azure_storage_account_name" {
  type        = string
  default     = "azurestorageaccount"
}

variable "azure_location" {
  type        = string
  default     = "West US"
}

resource "azurerm_resource_group" "azure_resource_group" {
  name     = var.azure_resource_group_name
  location = var.azure_location
}

resource "azurerm_storage_account" "azure_object_storage" {
  name                     = var.azure_storage_account_name
  resource_group_name      = azurerm_resource_group.azure_resource_group.name
  location                 = azurerm_resource_group.azure_resource_group.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = {
    Name        = "Azure Object Storage"
    Environment = "Dev"
  }
}

# GCP Cloud Storage
provider "google" {
  project = "your-project-id"
  region  = "us-central1"
}

variable "gcp_bucket_name" {
  type        = string
  default     = "gcp-object-storage"
}

resource "google_storage_bucket" "gcp_object_storage" {
  name     = var.gcp_bucket_name
  location = "US"

  versioning {
    enabled = true
  }

  labels = {
    Name        = "GCP Object Storage"
    Environment = "Dev"
  }
}