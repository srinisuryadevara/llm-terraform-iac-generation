# AWS Lambda
provider "aws" {
  region = var.aws_region
}

resource "aws_lambda_function" "aws_example" {
  function_name = "ServerlessExampleAWS"

  s3_bucket = var.aws_s3_bucket
  s3_key    = "v1.0.0/example.zip"

  handler = "main.handler"
  runtime = "nodejs10.x"

  role = aws_iam_role.lambda_exec.arn
}

resource "aws_iam_role" "lambda_exec" {
  name = "serverless_example_lambda_aws"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

# Azure Function App
provider "azurerm" {
  version = "3.34.0"
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

# GCP Cloud Functions
provider "google" {
  version = "4.34.0"
  project = var.gcp_project
  region  = var.gcp_region
}

resource "google_cloudfunctions_function" "example" {
  name        = "serverless-example-gcf"
  runtime     = "nodejs14"
  region      = var.gcp_region
  entry_point = "main"

  available_memory_mb   = 128
  source_archive_bucket = var.gcp_bucket
  source_archive_object = "example.zip"

  trigger_http {
    security_level = "SECURE_ALWAYS"
  }
}

resource "google_storage_bucket" "example" {
  name     = var.gcp_bucket
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

variable "gcp_project" {
  type = string
}

variable "gcp_region" {
  type = string
}

variable "gcp_bucket" {
  type = string
}