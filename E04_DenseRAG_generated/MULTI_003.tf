# AWS Lambda Function
provider "aws" {
  region = var.aws_region
}

resource "aws_lambda_function" "aws_example" {
  function_name = "ServerlessAWSExample"

  s3_bucket = var.aws_s3_bucket
  s3_key    = "v1.0.0/example.zip"

  handler = "main.handler"
  runtime = "nodejs10.x"

  role = aws_iam_role.aws_lambda_exec.arn
}

resource "aws_iam_role" "aws_lambda_exec" {
  name = "serverless_aws_example_lambda"

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
  version = "2.34.0"
  subscription_id = var.azure_subscription_id
  client_id      = var.azure_client_id
  client_secret = var.azure_client_secret
  tenant_id      = var.azure_tenant_id
}

resource "azurerm_resource_group" "azure_example" {
  name     = "serverless-azure-example"
  location = var.azure_location
}

resource "azurerm_storage_account" "azure_example" {
  name                     = "serverlessazureexample"
  resource_group_name      = azurerm_resource_group.azure_example.name
  location                 = azurerm_resource_group.azure_example.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_function_app" "azure_example" {
  name                       = "serverless-azure-example"
  location                   = azurerm_resource_group.azure_example.location
  resource_group_name        = azurerm_resource_group.azure_example.name
  app_service_plan_name      = azurerm_resource_group.azure_example.name
  storage_account_name       = azurerm_storage_account.azure_example.name
  storage_account_access_key = azurerm_storage_account.azure_example.primary_access_key
}

# GCP Cloud Function
provider "google" {
  version = "3.52.0"
  project = var.gcp_project
  region  = var.gcp_region
}

resource "google_cloudfunctions_function" "gcp_example" {
  name = "serverless-gcp-example"
  runtime = "nodejs10"

  available_memory_mb   = 128
  source_archive_bucket = var.gcp_bucket
  source_archive_object = "example.zip"
  trigger_http          = true
}

resource "google_storage_bucket" "gcp_example" {
  name = var.gcp_bucket
  location = var.gcp_region
  force_destroy = true
}

variable "aws_region" {
  type = string
}

variable "aws_s3_bucket" {
  type = string
}

variable "azure_subscription_id" {
  type = string
}

variable "azure_client_id" {
  type = string
}

variable "azure_client_secret" {
  type = string
}

variable "azure_tenant_id" {
  type = string
}

variable "azure_location" {
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