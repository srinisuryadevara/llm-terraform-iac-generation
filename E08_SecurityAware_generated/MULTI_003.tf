# AWS Lambda
provider "aws" {
  region = var.aws_region
}

resource "aws_iam_role" "lambda_exec" {
  name        = "lambda-exec-role"
  description = "Execution role for Lambda function"

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

  tags = {
    Environment = var.environment
    Project     = var.project
  }
}

resource "aws_iam_policy" "lambda_policy" {
  name        = "lambda-policy"
  description = "Policy for Lambda function"

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

  tags = {
    Environment = var.environment
    Project     = var.project
  }
}

resource "aws_iam_role_policy_attachment" "lambda_attach" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}

resource "aws_lambda_function" "example" {
  filename      = "lambda_function_payload.zip"
  function_name = "example_lambda"
  handler       = "index.handler"
  runtime       = "nodejs14.x"
  role          = aws_iam_role.lambda_exec.arn

  vpc_config {
    security_group_ids = [aws_security_group.lambda_sg.id]
    subnet_ids         = [aws_subnet.lambda_subnet.id]
  }

  tags = {
    Environment = var.environment
    Project     = var.project
  }
}

resource "aws_security_group" "lambda_sg" {
  name        = "lambda-sg"
  description = "Security group for Lambda function"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Environment = var.environment
    Project     = var.project
  }
}

resource "aws_subnet" "lambda_subnet" {
  cidr_block = "10.0.1.0/24"
  vpc_id     = aws_vpc.example.id
  availability_zone = "us-west-2a"

  tags = {
    Environment = var.environment
    Project     = var.project
  }
}

resource "aws_vpc" "example" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Environment = var.environment
    Project     = var.project
  }
}

# Azure Function App
provider "azurerm" {
  features {}
  subscription_id = var.azure_subscription_id
  client_id       = var.azure_client_id
  client_secret   = var.azure_client_secret
  tenant_id       = var.azure_tenant_id
}

resource "azurerm_resource_group" "example" {
  name     = "example-resource-group"
  location = var.azure_location

  tags = {
    Environment = var.environment
    Project     = var.project
  }
}

resource "azurerm_storage_account" "example" {
  name                     = "examplestorageaccount"
  resource_group_name      = azurerm_resource_group.example.name
  location                 = azurerm_resource_group.example.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = {
    Environment = var.environment
    Project     = var.project
  }
}

resource "azurerm_function_app" "example" {
  name                       = "example-function-app"
  location                   = azurerm_resource_group.example.location
  resource_group_name        = azurerm_resource_group.example.name
  app_service_plan_name      = azurerm_app_service_plan.example.name
  storage_account_name       = azurerm_storage_account.example.name
  storage_account_access_key = azurerm_storage_account.example.primary_access_key

  site_config {
    min_tls_version = "1.2"
  }

  tags = {
    Environment = var.environment
    Project     = var.project
  }
}

resource "azurerm_app_service_plan" "example" {
  name                = "example-app-service-plan"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  kind                = "FunctionApp"
  reserved            = true

  sku {
    tier = "Dynamic"
    size = "Y1"
  }

  tags = {
    Environment = var.environment
    Project     = var.project
  }
}

# GCP Cloud Functions
provider "google" {
  project = var.gcp_project
  region  = var.gcp_region
}

resource "google_cloudfunctions_function" "example" {
  name        = "example-cloud-function"
  runtime     = "nodejs14"
  trigger_http {
    security_level = "SECURE_ALWAYS"
    min_tls_version = "1.2"
  }

  source_archive_bucket = google_storage_bucket.example.name
  source_archive_object = google_storage_bucket_object.example.name

  tags = {
    Environment = var.environment
    Project     = var.project
  }
}

resource "google_storage_bucket" "example" {
  name     = "example-storage-bucket"
  location = var.gcp_region

  force_destroy = true

  tags = {
    Environment = var.environment
    Project     = var.project
  }
}

resource "google_storage_bucket_object" "example" {
  name   = "example-cloud-function-source.zip"
  bucket = google_storage_bucket.example.name
  source = "cloud_function_source.zip"
}

variable "aws_region" {
  type        = string
  description = "AWS region"
}

variable "azure_subscription_id" {
  type        = string
  description = "Azure subscription ID"
}

variable "azure_client_id" {
  type        = string
  description = "Azure client ID"
}

variable "azure_client_secret" {
  type        = string
  description = "Azure client secret"
}

variable "azure_tenant_id" {
  type        = string
  description = "Azure tenant ID"
}

variable "azure_location" {
  type        = string
  description = "Azure location"
}

variable "gcp_project" {
  type        = string
  description = "GCP project"
}

variable "gcp_region" {
  type        = string
  description = "GCP region"
}

variable "environment" {
  type        = string
  description = "Environment"
}

variable "project" {
  type        = string
  description = "Project"
}

variable "allowed_cidr" {
  type        = string
  description = "Allowed CIDR"
}