# Configure the AWS Provider
provider "aws" {
  region = var.aws_region
}

# Create an IAM role for the AWS Lambda function
resource "aws_iam_role" "aws_lambda_exec" {
  name = "aws_lambda_exec"

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

# Create an IAM policy for the AWS Lambda function
resource "aws_iam_policy" "aws_lambda_policy" {
  name        = "AWSLambdaPolicy"
  description = "IAM policy for AWS Lambda function"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
        ],
        Effect   = "Allow",
        Resource = "*",
      },
    ],
  })
}

# Attach the IAM policy to the IAM role
resource "aws_iam_role_policy_attachment" "aws_lambda_policy_attachment" {
  role       = aws_iam_role.aws_lambda_exec.name
  policy_arn = aws_iam_policy.aws_lambda_policy.arn
}

# Create the AWS Lambda function
resource "aws_lambda_function" "aws_lambda" {
  filename      = var.aws_lambda_filename
  function_name = var.aws_lambda_function_name
  handler       = var.aws_lambda_handler
  runtime       = var.aws_lambda_runtime
  role          = aws_iam_role.aws_lambda_exec.arn
}

# Configure the Azure Provider
provider "azurerm" {
  features {}
}

# Create a resource group for the Azure Function App
resource "azurerm_resource_group" "azure_function_app" {
  name     = var.azure_function_app_resource_group_name
  location = var.azure_function_app_location
}

# Create a storage account for the Azure Function App
resource "azurerm_storage_account" "azure_function_app" {
  name                     = var.azure_function_app_storage_account_name
  resource_group_name      = azurerm_resource_group.azure_function_app.name
  location                 = azurerm_resource_group.azure_function_app.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# Create a plan for the Azure Function App
resource "azurerm_app_service_plan" "azure_function_app" {
  name                = var.azure_function_app_plan_name
  resource_group_name = azurerm_resource_group.azure_function_app.name
  location            = azurerm_resource_group.azure_function_app.location
  kind                = "FunctionApp"
  reserved            = true

  sku {
    tier = "Dynamic"
    size = "Y1"
  }
}

# Create the Azure Function App
resource "azurerm_function_app" "azure_function_app" {
  name                       = var.azure_function_app_name
  resource_group_name        = azurerm_resource_group.azure_function_app.name
  location                   = azurerm_resource_group.azure_function_app.location
  app_service_plan_name      = azurerm_app_service_plan.azure_function_app.name
  app_service_plan_id        = azurerm_app_service_plan.azure_function_app.id
  storage_account_name       = azurerm_storage_account.azure_function_app.name
  storage_account_access_key = azurerm_storage_account.azure_function_app.primary_access_key
  os_type                    = "linux"
  version                   = "~3"
}

# Configure the Google Cloud Provider
provider "google" {
  project = var.gcp_project
  region  = var.gcp_region
}

# Create a Cloud Function on Google Cloud
resource "google_cloudfunctions_function" "gcp_cloud_function" {
  name        = var.gcp_cloud_function_name
  runtime     = var.gcp_cloud_function_runtime
  trigger_http {
    security_level = "SECURE_OPTIONAL"
  }
  available_memory_mb   = var.gcp_cloud_function_memory
  timeout               = var.gcp_cloud_function_timeout
  entry_point           = var.gcp_cloud_function_entry_point
  source_archive_bucket = var.gcp_cloud_function_bucket
  source_archive_object = var.gcp_cloud_function_object
}

variable "aws_region" {
  type        = string
  description = "AWS region"
}

variable "aws_lambda_filename" {
  type        = string
  description = "AWS Lambda filename"
}

variable "aws_lambda_function_name" {
  type        = string
  description = "AWS Lambda function name"
}

variable "aws_lambda_handler" {
  type        = string
  description = "AWS Lambda handler"
}

variable "aws_lambda_runtime" {
  type        = string
  description = "AWS Lambda runtime"
}

variable "azure_function_app_resource_group_name" {
  type        = string
  description = "Azure Function App resource group name"
}

variable "azure_function_app_location" {
  type        = string
  description = "Azure Function App location"
}

variable "azure_function_app_storage_account_name" {
  type        = string
  description = "Azure Function App storage account name"
}

variable "azure_function_app_plan_name" {
  type        = string
  description = "Azure Function App plan name"
}

variable "azure_function_app_name" {
  type        = string
  description = "Azure Function App name"
}

variable "gcp_project" {
  type        = string
  description = "GCP project"
}

variable "gcp_region" {
  type        = string
  description = "GCP region"
}

variable "gcp_cloud_function_name" {
  type        = string
  description = "GCP Cloud Function name"
}

variable "gcp_cloud_function_runtime" {
  type        = string
  description = "GCP Cloud Function runtime"
}

variable "gcp_cloud_function_memory" {
  type        = number
  description = "GCP Cloud Function memory"
}

variable "gcp_cloud_function_timeout" {
  type        = number
  description = "GCP Cloud Function timeout"
}

variable "gcp_cloud_function_entry_point" {
  type        = string
  description = "GCP Cloud Function entry point"
}

variable "gcp_cloud_function_bucket" {
  type        = string
  description = "GCP Cloud Function bucket"
}

variable "gcp_cloud_function_object" {
  type        = string
  description = "GCP Cloud Function object"
}