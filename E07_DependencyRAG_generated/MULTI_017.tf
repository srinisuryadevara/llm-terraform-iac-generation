# Configure the AWS Provider
provider "aws" {
  region = var.aws_region
}

# Create an IAM role for the AWS Lambda function
resource "aws_iam_role" "lambda_exec" {
  name        = "serverless_example_lambda"
  description = "Execution role for AWS Lambda"

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

# Create an IAM policy for the AWS Lambda function
resource "aws_iam_policy" "lambda_policy" {
  name        = "serverless_example_lambda_policy"
  description = "Policy for AWS Lambda"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
        ]
        Resource = "arn:aws:logs:*:*:*"
        Effect    = "Allow"
      }
    ]
  })
}

# Attach the IAM policy to the IAM role
resource "aws_iam_role_policy_attachment" "lambda_attach" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}

# Create a CloudWatch log group for the AWS Lambda function
resource "aws_cloudwatch_log_group" "lambda_logs" {
  name              = "/aws/lambda/serverless_example"
  retention_in_days = 14
}

# Create the AWS Lambda function
resource "aws_lambda_function" "example" {
  filename      = "example.zip"
  function_name = "ServerlessExample"
  handler       = "main.handler"
  runtime       = "nodejs16.x"
  role          = aws_iam_role.lambda_exec.arn
}

# Configure the Azure Provider
provider "azurerm" {
  features {}
}

# Create a resource group for the Azure Function App
resource "azurerm_resource_group" "example" {
  name     = "serverless_example"
  location = var.azure_location
}

# Create a storage account for the Azure Function App
resource "azurerm_storage_account" "example" {
  name                     = "serverlessexamplestorage"
  resource_group_name      = azurerm_resource_group.example.name
  location                 = azurerm_resource_group.example.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# Create an app service plan for the Azure Function App
resource "azurerm_app_service_plan" "example" {
  name                = "serverless_example_plan"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  kind                = "FunctionApp"
  reserved            = true

  sku {
    tier = "Dynamic"
    size = "Y1"
  }
}

# Create the Azure Function App
resource "azurerm_function_app" "example" {
  name                       = "serverless-example"
  resource_group_name        = azurerm_resource_group.example.name
  location                   = azurerm_resource_group.example.location
  app_service_plan_name      = azurerm_app_service_plan.example.name
  app_service_plan_id        = azurerm_app_service_plan.example.id
  storage_account_name       = azurerm_storage_account.example.name
  storage_account_access_key = azurerm_storage_account.example.primary_access_key
}

# Configure the Google Cloud Provider
provider "google" {
  project = var.gcp_project
  region  = var.gcp_region
}

# Create a service account for the Google Cloud Function
resource "google_service_account" "example" {
  account_id = "serverless-example"
}

# Create a Cloud Function for Google Cloud
resource "google_cloudfunctions_function" "example" {
  name        = "serverless-example"
  runtime     = "nodejs16"
  region      = var.gcp_region
  entry_point = "main"

  available_memory_mb   = 128
  source_archive_bucket = var.gcp_bucket
  source_archive_object = var.gcp_object

  service_account_email = google_service_account.example.email
}