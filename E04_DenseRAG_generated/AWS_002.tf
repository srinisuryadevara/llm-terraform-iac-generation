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
    bucket         = var.bucket
    key            = "terraform.tfstate"
    region         = var.region
    dynamodb_table = "terraform-lock"
    encrypt        = true
  }
}

# DynamoDB for terraform state lock
resource "aws_dynamodb_table" "terraform_state_lock" {
  name         = "terraform-lock"
  hash_key     = "LockID"
  billing_mode = "PAY_PER_REQUEST"

  attribute {
    name = "LockID"
    type = "S"
  }
}

# Create a KMS customer managed key
resource "aws_kms_key" "this" {
  description             = var.description
  policy                  = var.policy
  enable_key_rotation     = var.enable_key_rotation
  deletion_window_in_days = var.deletion_window_in_days
  tags                    = var.tags
}

# Assign an alias to the key
resource "aws_kms_alias" "this" {
  name          = var.alias
  target_key_id = aws_kms_key.this.key_id
}

variable "bucket" {
  type        = string
  sensitive   = true
  description = "The name of the S3 bucket for Terraform state"
}

variable "region" {
  type        = string
  sensitive   = true
  description = "The AWS region for the S3 bucket"
}

variable "description" {
  type        = string
  description = "The description of the KMS key"
}

variable "policy" {
  type        = string
  description = "The policy of the KMS key"
}

variable "enable_key_rotation" {
  type        = bool
  description = "Whether to enable key rotation"
}

variable "deletion_window_in_days" {
  type        = number
  description = "The deletion window in days"
}

variable "tags" {
  type        = map(string)
  description = "The tags for the KMS key"
}

variable "alias" {
  type        = string
  description = "The alias for the KMS key"
}