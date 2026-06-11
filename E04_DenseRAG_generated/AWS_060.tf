# Configure the AWS Provider
terraform {
  required_version = ">= 1.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.47"
    }
  }

  backend "s3" {
    bucket         = var.tfstate_bucket
    key            = "terraform.tfstate"
    region         = var.tfstate_region
    dynamodb_table = var.tfstate_dynamodb_table
    encrypt        = true
  }
}

# Create a DynamoDB table for Terraform state lock
resource "aws_dynamodb_table" "terraform_state_lock" {
  name         = var.tfstate_dynamodb_table
  hash_key     = "LockID"
  billing_mode = "PAY_PER_REQUEST"

  attribute {
    name = "LockID"
    type = "S"
  }
}

# Get the current AWS account ID and region
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# Define locals
locals {
  account_id = data.aws_caller_identity.current.account_id
  region     = data.aws_region.current.name
}

# Create a KMS key
resource "aws_kms_key" "this" {
  description             = var.description
  policy                  = var.policy
  enable_key_rotation     = var.enable_key_rotation
  deletion_window_in_days = var.deletion_window_in_days
  tags                    = var.tags
}

# Create an alias for the KMS key
resource "aws_kms_alias" "this" {
  name          = var.alias
  target_key_id = aws_kms_key.this.key_id
}