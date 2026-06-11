# Configure the AWS Provider
provider "aws" {
  region = var.aws_region
}

# Configure the Azure Provider
provider "azurerm" {
  features {}
  subscription_id = var.azure_subscription_id
  client_id      = var.azure_client_id
  client_secret = var.azure_client_secret
  tenant_id      = var.azure_tenant_id
}

# Configure the GCP Provider
provider "google" {
  project = var.gcp_project
  region  = var.gcp_region
}

# AWS Lambda Function
resource "aws_lambda_function" "aws_lambda" {
  filename      = "lambda_function_payload.zip"
  function_name = "aws-lambda-function"
  handler       = "index.handler"
  runtime       = "nodejs14.x"
  role          = aws_iam_role.aws_lambda_exec.arn
}

resource "aws_iam_role" "aws_lambda_exec" {
  name        = "aws-lambda-exec"
  description = "Execution role for AWS Lambda"

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
}

resource "aws_iam_policy" "aws_lambda_policy" {
  name        = "aws-lambda-policy"
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
        Effect = "Allow"
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "aws_lambda_attach" {
  role       = aws_iam_role.aws_lambda_exec.name
  policy_arn = aws_iam_policy.aws_lambda_policy.arn
}

# Azure Function App
resource "azurerm_resource_group" "azure_rg" {
  name     = "azure-resource-group"
  location = var.azure_location
}

resource "azurerm_storage_account" "azure_storage" {
  name                     = "azurestorageaccount"
  resource_group_name      = azurerm_resource_group.azure_rg.name
  location                 = azurerm_resource_group.azure_rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_app_service_plan" "azure_plan" {
  name                = "azure-app-service-plan"
  resource_group_name = azurerm_resource_group.azure_rg.name
  location            = azurerm_resource_group.azure_rg.location
  kind                = "FunctionApp"
  reserved            = true

  sku {
    tier = "Dynamic"
    size = "Y1"
  }
}

resource "azurerm_function_app" "azure_function" {
  name                      = "azure-function-app"
  resource_group_name = azurerm_resource_group.azure_rg.name
  location                = azurerm_resource_group.azure_rg.location
  app_service_plan_name = azurerm_app_service_plan.azure_plan.name
  storage_account_name  = azurerm_storage_account.azure_storage.name
  os_type                = "linux"
  version                = "~3"
}

# GCP Cloud Function
resource "google_cloudfunctions_function" "gcp_function" {
  name        = "gcp-cloud-function"
  runtime     = "nodejs14"
  trigger_http {
    security_level = "SECURE_ALWAYS"
  }
}

resource "google_cloudfunctions_function_iam_member" "gcp_invoker" {
  project        = var.gcp_project
  region         = var.gcp_region
  cloud_function = google_cloudfunctions_function.gcp_function.name
  role           = "roles/cloudfunctions.invoker"
  member         = "allUsers"
}