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

# AWS Lambda Function
resource "aws_lambda_function" "aws_lambda" {
  filename      = var.aws_lambda_filename
  function_name = var.aws_lambda_function_name
  handler       = var.aws_lambda_handler
  runtime       = var.aws_lambda_runtime
  role          = aws_iam_role.aws_lambda_exec.arn

  tags = {
    Environment = "serverless"
    Provider    = "AWS"
  }
}

# AWS IAM Role for Lambda
resource "aws_iam_role" "aws_lambda_exec" {
  name        = var.aws_lambda_exec_role_name
  description = var.aws_lambda_exec_role_description

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Environment = "serverless"
    Provider    = "AWS"
  }
}

# Azure Function App
resource "azurerm_resource_group" "azure_function_app" {
  name     = var.azure_function_app_resource_group_name
  location = var.azure_function_app_location

  tags = {
    Environment = "serverless"
    Provider    = "Azure"
  }
}

resource "azurerm_storage_account" "azure_function_app" {
  name                     = var.azure_function_app_storage_account_name
  resource_group_name      = azurerm_resource_group.azure_function_app.name
  location                 = azurerm_resource_group.azure_function_app.location
  account_tier             = var.azure_function_app_storage_account_tier
  account_replication_type = var.azure_function_app_storage_account_replication_type

  tags = {
    Environment = "serverless"
    Provider    = "Azure"
  }
}

resource "azurerm_function_app" "azure_function_app" {
  name                       = var.azure_function_app_name
  location                   = azurerm_resource_group.azure_function_app.location
  resource_group_name        = azurerm_resource_group.azure_function_app.name
  app_service_plan_name      = azurerm_app_service_plan.azure_function_app.name
  storage_account_name       = azurerm_storage_account.azure_function_app.name
  storage_account_access_key = azurerm_storage_account.azure_function_app.primary_access_key

  tags = {
    Environment = "serverless"
    Provider    = "Azure"
  }
}

resource "azurerm_app_service_plan" "azure_function_app" {
  name                = var.azure_function_app_service_plan_name
  location            = azurerm_resource_group.azure_function_app.location
  resource_group_name = azurerm_resource_group.azure_function_app.name
  kind                = var.azure_function_app_service_plan_kind
  reserved            = var.azure_function_app_service_plan_reserved

  sku {
    tier = var.azure_function_app_service_plan_tier
    size = var.azure_function_app_service_plan_size
  }

  tags = {
    Environment = "serverless"
    Provider    = "Azure"
  }
}

# GCP Cloud Function
resource "google_cloudfunctions_function" "gcp_cloud_function" {
  name        = var.gcp_cloud_function_name
  runtime     = var.gcp_cloud_function_runtime
  region      = var.gcp_region
  trigger_http {
    security_level = var.gcp_cloud_function_security_level
  }

  labels = {
    Environment = "serverless"
    Provider    = "Google Cloud"
  }
}

variable "aws_region" {
  type        = string
  sensitive   = true
}

variable "aws_lambda_filename" {
  type        = string
  sensitive   = true
}

variable "aws_lambda_function_name" {
  type        = string
  sensitive   = true
}

variable "aws_lambda_handler" {
  type        = string
  sensitive   = true
}

variable "aws_lambda_runtime" {
  type        = string
  sensitive   = true
}

variable "aws_lambda_exec_role_name" {
  type        = string
  sensitive   = true
}

variable "aws_lambda_exec_role_description" {
  type        = string
  sensitive   = true
}

variable "azure_function_app_resource_group_name" {
  type        = string
  sensitive   = true
}

variable "azure_function_app_location" {
  type        = string
  sensitive   = true
}

variable "azure_function_app_storage_account_name" {
  type        = string
  sensitive   = true
}

variable "azure_function_app_storage_account_tier" {
  type        = string
  sensitive   = true
}

variable "azure_function_app_storage_account_replication_type" {
  type        = string
  sensitive   = true
}

variable "azure_function_app_name" {
  type        = string
  sensitive   = true
}

variable "azure_function_app_service_plan_name" {
  type        = string
  sensitive   = true
}

variable "azure_function_app_service_plan_kind" {
  type        = string
  sensitive   = true
}

variable "azure_function_app_service_plan_reserved" {
  type        = bool
  sensitive   = true
}

variable "azure_function_app_service_plan_tier" {
  type        = string
  sensitive   = true
}

variable "azure_function_app_service_plan_size" {
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

variable "gcp_cloud_function_name" {
  type        = string
  sensitive   = true
}

variable "gcp_cloud_function_runtime" {
  type        = string
  sensitive   = true
}

variable "gcp_cloud_function_security_level" {
  type        = string
  sensitive   = true
}

output "aws_lambda_function_arn" {
  value       = aws_lambda_function.aws_lambda.arn
  description = "The ARN of the AWS Lambda function"
}

output "azure_function_app_url" {
  value       = azurerm_function_app.azure_function_app.default_hostname
  description = "The URL of the Azure Function App"
}

output "gcp_cloud_function_url" {
  value       = google_cloudfunctions_function.gcp_cloud_function.https_trigger_url
  description = "The URL of the GCP Cloud Function"
}