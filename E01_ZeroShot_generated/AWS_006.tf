provider "aws" {
  region = var.aws_region
}

resource "aws_kms_key" "dynamodb" {
  description             = "KMS key for DynamoDB encryption"
  deletion_window_in_days = 10
}

resource "aws_kms_alias" "dynamodb" {
  name          = "alias/dynamodb-kms-key"
  target_key_id = aws_kms_key.dynamodb.key_id
}

resource "aws_dynamodb_table" "example" {
  name           = var.dynamodb_table_name
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = var.dynamodb_hash_key
  range_key       = var.dynamodb_range_key
  read_capacity_units  = 1
  write_capacity_units = 1
  attribute {
    name = var.dynamodb_hash_key
    type = "S"
  }
  attribute {
    name = var.dynamodb_range_key
    type = "S"
  }
  attribute {
    name = "gsi_attribute"
    type = "S"
  }
  global_secondary_index {
    name               = "gsi_index"
    hash_key           = "gsi_attribute"
    projection_type    = "INCLUDE"
    non_key_attributes = ["attribute1", "attribute2"]
  }
  point_in_time_recovery {
    enabled = true
  }
  server_side_encryption {
    enabled = true
    kms_key_arn = aws_kms_key.dynamodb.arn
  }
  tags = {
    Name        = var.dynamodb_table_name
    Environment = var.environment
  }
}

variable "aws_region" {
  type        = string
  sensitive = true
}

variable "dynamodb_table_name" {
  type        = string
  sensitive = true
}

variable "dynamodb_hash_key" {
  type        = string
  sensitive = true
}

variable "dynamodb_range_key" {
  type        = string
  sensitive = true
}

variable "environment" {
  type        = string
  sensitive = true
}