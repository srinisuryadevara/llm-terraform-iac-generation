# Configure the AWS Provider
provider "aws" {
  region = var.aws_region
}

# Configure the Azure Provider
provider "azurerm" {
  features {}
  subscription_id = var.azure_subscription_id
  client_id       = var.azure_client_id
  client_secret   = var.azure_client_secret
  tenant_id       = var.azure_tenant_id
}

# Configure the GCP Provider
provider "google" {
  project = var.gcp_project
  region  = var.gcp_region
}

# AWS Lambda Function
resource "aws_lambda_function" "example" {
  filename      = "lambda_function_payload.zip"
  function_name = "example_lambda_function"
  handler       = "index.handler"
  runtime       = "nodejs14.x"
  role          = aws_iam_role.lambda_exec.arn
  tags = {
    Environment = var.environment
  }
}

# AWS IAM Role for Lambda
resource "aws_iam_role" "lambda_exec" {
  name        = "example_lambda_exec"
  description = "Execution role for example lambda function"

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

# AWS IAM Policy for Lambda
resource "aws_iam_policy" "lambda_policy" {
  name        = "example_lambda_policy"
  description = "Policy for example lambda function"

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

# AWS IAM Role Policy Attachment
resource "aws_iam_role_policy_attachment" "lambda_attach" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}

# Azure Function App
resource "azurerm_function_app" "example" {
  name                      = "example-function-app"
  location                  = var.azure_location
  resource_group_name       = var.azure_resource_group
  app_service_plan_name     = azurerm_app_service_plan.example.name
  storage_account_name      = azurerm_storage_account.example.name
  storage_account_access_key = azurerm_storage_account.example.primary_access_key
  os_type                    = "linux"
  version                   = "~3"

  site_config {
    linux_fx_version = "DOCKER|mcr.microsoft.com/azure-app-service/samples/node:12-lts"
    min_tls_version  = "1.2"
  }

  tags = {
    Environment = var.environment
  }
}

# Azure App Service Plan
resource "azurerm_app_service_plan" "example" {
  name                = "example-app-service-plan"
  location            = var.azure_location
  resource_group_name = var.azure_resource_group
  kind                = "Linux"
  reserved            = true

  sku {
    tier = "Standard"
    size = "S1"
  }

  tags = {
    Environment = var.environment
  }
}

# Azure Storage Account
resource "azurerm_storage_account" "example" {
  name                     = "examplestorageaccount"
  location                 = var.azure_location
  resource_group_name      = var.azure_resource_group
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"
  is_hns_enabled           = true

  blob_properties {
    versioning_enabled = true
    change_feed_enabled = true
  }

  tags = {
    Environment = var.environment
  }
}

# GCP Cloud Function
resource "!google_cloudfunctions_function" "example" {
  name        = "example-cloud-function"
  runtime     = "nodejs14"
  region      = var.gcp_region
  entry_point = "helloWorld"

  available_memory_mb   = 128
  source_archive_bucket = google_storage_bucket.example.name
  source_archive_object = google_storage_bucket_object.example.name

  https_trigger {
    security_level = "SECURE_ALWAYS"
    min_tls_version = "1.2"
  }

  tags = {
    Environment = var.environment
  }
}

# GCP Storage Bucket
resource "google_storage_bucket" "example" {
  name                        = "example-storage-bucket"
  location                    = var.gcp_region
  force_destroy               = true
  uniform_bucket_level_access = true

  encryption {
    default_kms_key_name = google_kms_key_ring.example.self_link
  }

  tags = {
    Environment = var.environment
  }
}

# GCP Storage Bucket Object
resource "google_storage_bucket_object" "example" {
  name   = "example-bucket-object"
  bucket = google_storage_bucket.example.name
  source = "cloud_function_payload.zip"
}

# GCP KMS Key Ring
resource "google_kms_key_ring" "example" {
  name     = "example-key-ring"
  location = var.gcp_region
}

# GCP KMS Key
resource "google_kms_crypto_key" "example" {
  name            = "example-key"
  key_ring        = google_kms_key_ring.example.self_link
  rotation_period = "7776000s"
}

variable "aws_region" {
  type        = string
  description = "AWS Region"
}

variable "azure_subscription_id" {
  type        = string
  description = "Azure Subscription ID"
}

variable "azure_client_id" {
  type        = string
  description = "Azure Client ID"
}

variable "azure_client_secret" {
  type        = string
  description = "Azure Client Secret"
}

variable "azure_tenant_id" {
  type        = string
  description = "Azure Tenant ID"
}

variable "azure_location" {
  type        = string
  description = "Azure Location"
}

variable "azure_resource_group" {
  type        = string
  description = "Azure Resource Group"
}

variable "gcp_project" {
  type        = string
  description = "GCP Project"
}

variable "gcp_region" {
  type        = string
  description = "GCP Region"
}

variable "environment" {
  type        = string
  description = "Environment"
}