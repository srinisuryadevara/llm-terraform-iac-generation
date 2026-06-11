provider "aws" {
  region = var.region
}

variable "region" {
  type        = string
  description = "AWS Region"
}

variable "table_name" {
  type        = string
  description = "DynamoDB Table Name"
}

variable "attribute_name" {
  type        = string
  description = "DynamoDB Attribute Name"
}

variable "attribute_type" {
  type        = string
  description = "DynamoDB Attribute Type"
}

variable "gsi_name" {
  type        = string
  description = "DynamoDB GSI Name"
}

variable "gsi_attribute_name" {
  type        = string
  description = "DynamoDB GSI Attribute Name"
}

variable "kms_key_arn" {
  type        = string
  description = "KMS Key ARN for DynamoDB Table Encryption"
}

resource "aws_dynamodb_table" "example" {
  name           = var.table_name
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = var.attribute_name
  attribute {
    name = var.attribute_name
    type = var.attribute_type
  }
  global_secondary_index {
    name               = var.gsi_name
    hash_key           = var.gsi_attribute_name
    projection_type    = "INCLUDE"
    non_key_attributes = [var.attribute_name]
  }
  point_in_time_recovery {
    enabled = true
  }
  server_side_encryption {
    enabled = true
    kms_key_arn = var.kms_key_arn
  }
}

resource "aws_kms_key" "example" {
  description             = "KMS Key for DynamoDB Table Encryption"
  deletion_window_in_days = 10
}

resource "aws_kms_alias" "example" {
  name          = "alias/dynamodb-encryption-key"
  target_key_id = aws_kms_key.example.key_id
}