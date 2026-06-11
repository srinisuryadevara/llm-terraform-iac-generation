provider "aws" {
  region = var.aws_region
}

provider "azurerm" {
  features {}
  subscription_id = var.azure_subscription_id
  client_id       = var.azure_client_id
  client_secret   = var.azure_client_secret
  tenant_id       = var.azure_tenant_id
}

provider "google" {
  project = var.gcp_project
  region  = var.gcp_region
}

variable "aws_region" {
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

variable "gcp_project" {
  type = string
}

variable "gcp_region" {
  type = string
}

variable "function_name" {
  type = string
}

variable "function_runtime" {
  type = string
}

variable "function_handler" {
  type = string
}

variable "function_code" {
  type = string
}

resource "aws_lambda_function" "example" {
  filename      = var.function_code
  function_name = var.function_name
  handler       = var.function_handler
  runtime       = var.function_runtime
  role          = aws_iam_role.example.arn
}

resource "aws_iam_role" "example" {
  name        = var.function_name
  description = "Execution role for ${var.function_name}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Effect = "Allow"
      }
    ]
  })
}

resource "azurerm_resource_group" "example" {
  name     = var.function_name
  location = var.gcp_region
}

resource "azurerm_storage_account" "example" {
  name                     = var.function_name
  resource_group_name      = azurerm_resource_group.example.name
  location                 = azurerm_resource_group.example.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_function_app" "example" {
  name                       = var.function_name
  location                   = azurerm_resource_group.example.location
  resource_group_name        = azurerm_resource_group.example.name
  app_service_plan_name      = azurerm_app_service_plan.example.name
  storage_account_name       = azurerm_storage_account.example.name
  storage_account_access_key = azurerm_storage_account.example.primary_access_key
  os_type                    = "linux"
  version                    = "~3"
}

resource "azurerm_app_service_plan" "example" {
  name                = var.function_name
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  kind                = "linux"
  reserved            = true

  sku {
    tier = "Standard"
    size = "S1"
  }
}

resource "google_cloud_functions_function" "example" {
  name        = var.function_name
  runtime     = var.function_runtime
  trigger_http {
    security_level = "SECURE_ALWAYS"
  }
  available_memory_mb   = 128
  source_archive_bucket = google_storage_bucket.example.name
  source_archive_object = google_storage_bucket_object.example.name
  entry_point          = var.function_handler
}

resource "google_storage_bucket" "example" {
  name     = var.function_name
  location = var.gcp_region
}

resource "google_storage_bucket_object" "example" {
  name   = "${var.function_name}.zip"
  bucket = google_storage_bucket.example.name
  source = var.function_code
}