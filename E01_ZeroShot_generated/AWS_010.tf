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
  read_capacity_units  = var.dynamodb_read_capacity_units
  write_capacity_units = var.dynamodb_write_capacity_units
  point_in_time_recovery {
    enabled = true
  }
  server_side_encryption {
    enabled = true
    kms_key_arn = aws_kms_key.dynamodb.arn
  }
  attribute {
    name = var.dynamodb_hash_key
    type = "S"
  }
  attribute {
    name = var.dynamodb_range_key
    type = "S"
  }
  attribute {
    name = var.dynamodb_gsi_attribute
    type = "S"
  }
  global_secondary_index {
    name               = var.dynamodb_gsi_name
    hash_key           = var.dynamodb_gsi_attribute
    projection_type    = "INCLUDE"
    non_key_attributes = var.dynamodb_gsi_non_key_attributes
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

variable "dynamodb_hash_key" {
  type        = string
  sensitive   = true
}

variable "dynamodb_range_key" {
  type        = string
  sensitive   = true
}

variable "dynamodb_read_capacity_units" {
  type        = number
  sensitive   = true
}

variable "dynamodb_write_capacity_units" {
  type        = number
  sensitive   = true
}

variable "dynamodb_gsi_attribute" {
  type        = string
  sensitive   = true
}

variable "dynamodb_gsi_name" {
  type        = string
  sensitive   = true
}

variable "dynamodb_gsi_non_key_attributes" {
  type        = list(string)
  sensitive   = true
}

variable "environment" {
  type        = string
  sensitive   = true
}