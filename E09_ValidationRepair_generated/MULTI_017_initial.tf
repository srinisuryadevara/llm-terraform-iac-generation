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
}

# AWS IAM Role for Lambda
resource "aws_iam_role" "aws_lambda_exec" {
  name        = var.aws_lambda_exec_role_name
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

# Azure Function App
resource "azurerm_resource_group" "azure_rg" {
  name     = var.azure_rg_name
  location = var.azure_location
}

resource "azurerm_storage_account" "azure_sa" {
  name                     = var.azure_sa_name
  resource_group_name      = azurerm_resource_group.azure_rg.name
  location                 = azurerm_resource_group.azure_rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_function_app" "azure_fa" {
  name                       = var.azure_fa_name
  location                   = azurerm_resource_group.azure_rg.location
  resource_group_name        = azurerm_resource_group.azure_rg.name
  app_service_plan_name      = azurerm_app_service_plan.azure_asp.name
  storage_account_name       = azurerm_storage_account.azure_sa.name
  storage_account_access_key = azurerm_storage_account.azure_sa.primary_access_key
}

resource "azurerm_app_service_plan" "azure_asp" {
  name                = var.azure_asp_name
  location            = azurerm_resource_group.azure_rg.location
  resource_group_name = azurerm_resource_group.azure_rg.name
  kind                = "FunctionApp"
  reserved            = true

  sku {
    tier = "Dynamic"
    size = "Y1"
  }
}

# GCP Cloud Function
resource "google_cloudfunctions_function" "gcp_cf" {
  name        = var.gcp_cf_name
  runtime     = var.gcp_cf_runtime
  trigger_http {
    url = var.gcp_cf_trigger_url
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

variable "azure_rg_name" {
  type        = string
  sensitive   = true
}

variable "azure_location" {
  type        = string
  sensitive   = true
}

variable "azure_sa_name" {
  type        = string
  sensitive   = true
}

variable "azure_fa_name" {
  type        = string
  sensitive   = true
}

variable "azure_asp_name" {
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

variable "gcp_cf_name" {
  type        = string
  sensitive   = true
}

variable "gcp_cf_runtime" {
  type        = string
  sensitive   = true
}

variable "gcp_cf_trigger_url" {
  type        = string
  sensitive   = true
}