# AWS Lambda Function
provider "aws" {
  region = var.aws_region
}

resource "aws_iam_role" "lambda_exec" {
  name = "serverless_example_lambda"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_lambda_function" "example" {
  function_name = "ServerlessExample"

  s3_bucket = var.aws_s3_bucket
  s3_key    = "v1.0.0/example.zip"

  handler = "main.handler"
  runtime = "nodejs10.x"

  role = aws_iam_role.lambda_exec.arn
}

# Azure Function App
provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "example" {
  name     = "serverless-example-rg"
  location = var.azure_location
}

resource "azurerm_storage_account" "example" {
  name                     = var.azure_storage_account_name
  resource_group_name      = azurerm_resource_group.example.name
  location                 = azurerm_resource_group.example.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_function_app" "example" {
  name                       = "serverless-example-fa"
  location                   = azurerm_resource_group.example.location
  resource_group_name        = azurerm_resource_group.example.name
  app_service_plan_name      = azurerm_app_service_plan.example.name
  storage_account_name       = azurerm_storage_account.example.name
  storage_account_access_key = azurerm_storage_account.example.primary_access_key
}

resource "azurerm_app_service_plan" "example" {
  name                = "serverless-example-asp"
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
provider "google" {
  project = var.gcp_project_id
  region  = var.gcp_region
}

resource "google_cloudfunctions_function" "example" {
  name        = "serverless-example-cf"
  runtime     = "nodejs10"
  trigger_http {
    security_level = "SECURE_ALWAYS"
  }
  available_memory_mb   = 128
  source_archive_bucket = var.gcp_source_archive_bucket
  source_archive_object = var.gcp_source_archive_object
  entry_point           = "main"
}

resource "google_storage_bucket" "example" {
  name     = var.gcp_source_archive_bucket
  location = var.gcp_region
}

variable "aws_region" {
  type = string
}

variable "aws_s3_bucket" {
  type = string
}

variable "azure_location" {
  type = string
}

variable "azure_storage_account_name" {
  type = string
}

variable "gcp_project_id" {
  type = string
}

variable "gcp_region" {
  type = string
}

variable "gcp_source_archive_bucket" {
  type = string
}

variable "gcp_source_archive_object" {
  type = string
}