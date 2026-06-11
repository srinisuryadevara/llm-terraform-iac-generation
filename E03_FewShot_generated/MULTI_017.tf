# Configure the AWS Provider
provider "aws" {
  region = var.aws_region
}

# Configure the Azure Provider
provider "azurerm" {
  features {}
}

# Configure the GCP Provider
provider "google" {
  project = var.gcp_project
  region  = var.gcp_region
}

# AWS Lambda Function
resource "aws_lambda_function" "example" {
  filename      = "lambda_function_payload.zip"
  function_name = "example_lambda"
  handler       = "index.handler"
  runtime       = "nodejs14.x"
  role          = aws_iam_role.example.arn
}

# AWS IAM Role for Lambda
resource "aws_iam_role" "example" {
  name        = "example_lambda_role"
  description = "Execution role for example lambda"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Effect = "Allow"
        Sid      = ""
      }
    ]
  })
}

# Azure Function App
resource "azurerm_resource_group" "example" {
  name     = "example-resource-group"
  location = var.azure_location
}

resource "azurerm_storage_account" "example" {
  name                     = "examplestorageaccount"
  resource_group_name      = azurerm_resource_group.example.name
  location                 = azurerm_resource_group.example.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_function_app" "example" {
  name                       = "example-function-app"
  location                   = azurerm_resource_group.example.location
  resource_group_name        = azurerm_resource_group.example.name
  app_service_plan_name      = azurerm_app_service_plan.example.name
  storage_account_name       = azurerm_storage_account.example.name
  storage_account_access_key = azurerm_storage_account.example.primary_access_key
}

resource "azurerm_app_service_plan" "example" {
  name                = "example-app-service-plan"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  kind                = "FunctionApp"
  reserved            = true

  sku {
    tier = "Dynamic"
    size = "Y1"
  }
}

# GCP Cloud Function
resource "google_cloudfunctions_function" "example" {
  name        = "example-cloud-function"
  runtime     = "nodejs14"
  region      = var.gcp_region
  entry_point = "helloWorld"

  available_memory_mb   = 128
  source_archive_bucket = google_storage_bucket.example.name
  source_archive_object = google_storage_bucket_object.example.name
  trigger_http {
    security_level = "SECURE_ALWAYS"
  }
}

resource "google_storage_bucket" "example" {
  name     = "example-bucket"
  location = var.gcp_region
}

resource "google_storage_bucket_object" "example" {
  name   = "example-object.zip"
  bucket = google_storage_bucket.example.name
  source = "cloud_function_payload.zip"
}

variable "aws_region" {
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

variable "azure_location" {
  type        = string
  sensitive   = true
}