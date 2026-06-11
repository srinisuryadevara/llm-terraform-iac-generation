provider "aws" {
  region = var.aws_region
}

resource "aws_kms_key" "dynamodb" {
  description             = "KMS key for DynamoDB table"
  deletion_window_in_days = 10
}

resource "aws_kms_alias" "dynamodb" {
  name          = "alias/dynamodb-kms-key"
  target_key_id = aws_kms_key.dynamodb.key_id
}

resource "aws_dynamodb_table" "example" {
  name           = var.dynamodb_table_name
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "id"
  attribute {
    name = "id"
    type = "S"
  }
  attribute {
    name = "sort_key"
    type = "S"
  }
  attribute {
    name = "data"
    type = "S"
  }
  global_secondary_index {
    name               = "GSI_1"
    hash_key           = "sort_key"
    projection_type    = "INCLUDE"
    non_key_attributes = ["data"]
  }
  point_in_time_recovery {
    enabled = true
  }
  server_side_encryption {
    enabled     = true
    kms_key_arn = aws_kms_key.dynamodb.arn
  }
  tags = {
    Name        = var.dynamodb_table_name
    Environment = var.environment
  }
}

variable "aws_region" {
  type        = string
  sensitive   = true
}

variable "dynamodb_table_name" {
  type        = string
  sensitive   = true
}

variable "environment" {
  type        = string
  sensitive   = true
}

output "dynamodb_table_name" {
  value       = aws_dynamodb_table.example.name
  description = "The name of the DynamoDB table"
}

output "dynamodb_table_arn" {
  value       = aws_dynamodb_table.example.arn
  description = "The ARN of the DynamoDB table"
}

output "dynamodb_table_id" {
  value       = aws_dynamodb_table.example.id
  description = "The ID of the DynamoDB table"
}

output "kms_key_arn" {
  value       = aws_kms_key.dynamodb.arn
  description = "The ARN of the KMS key"
}

output "kms_key_id" {
  value       = aws_kms_key.dynamodb.key_id
  description = "The ID of the KMS key"
}