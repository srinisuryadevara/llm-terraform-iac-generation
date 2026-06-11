provider "aws" {
  region = var.aws_region
}

variable "aws_region" {
  type        = string
  description = "AWS Region"
}

variable "project_name" {
  type        = string
  description = "Project Name"
}

variable "environment" {
  type        = string
  description = "Environment"
}

variable "dynamodb_table_name" {
  type        = string
  description = "DynamoDB Table Name"
}

variable "dynamodb_read_capacity_units" {
  type        = number
  description = "DynamoDB Read Capacity Units"
}

variable "dynamodb_write_capacity_units" {
  type        = number
  description = "DynamoDB Write Capacity Units"
}

variable "dynamodb_attribute_name" {
  type        = string
  description = "DynamoDB Attribute Name"
}

variable "dynamodb_attribute_type" {
  type        = string
  description = "DynamoDB Attribute Type"
}

variable "dynamodb_gsi_name" {
  type        = string
  description = "DynamoDB GSI Name"
}

variable "dynamodb_gsi_projection_type" {
  type        = string
  description = "DynamoDB GSI Projection Type"
}

variable "dynamodb_gsi_read_capacity_units" {
  type        = number
  description = "DynamoDB GSI Read Capacity Units"
}

variable "dynamodb_gsi_write_capacity_units" {
  type        = number
  description = "DynamoDB GSI Write Capacity Units"
}

variable "kms_key_arn" {
  type        = string
  description = "KMS Key ARN"
}

resource "aws_kms_key" "dynamodb" {
  description             = "KMS Key for DynamoDB"
  deletion_window_in_days = 10
  tags = {
    Name        = "${var.project_name}-${var.environment}-dynamodb-kms-key"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_kms_alias" "dynamodb" {
  name          = "alias/${var.project_name}-${var.environment}-dynamodb-kms-key"
  target_key_id = aws_kms_key.dynamodb.key_id
}

resource "aws_dynamodb_table" "example" {
  name           = var.dynamodb_table_name
  read_capacity_units  = var.dynamodb_read_capacity_units
  write_capacity_units = var.dynamodb_write_capacity_units
  attribute {
    name = var.dynamodb_attribute_name
    type = var.dynamodb_attribute_type
  }
  global_secondary_index {
    name               = var.dynamodb_gsi_name
    hash_key           = var.dynamodb_attribute_name
    projection_type    = var.dynamodb_gsi_projection_type
    read_capacity_units  = var.dynamodb_gsi_read_capacity_units
    write_capacity_units = var.dynamodb_gsi_write_capacity_units
  }
  point_in_time_recovery {
    enabled = true
  }
  server_side_encryption {
    enabled = true
    kms_key_arn = var.kms_key_arn
  }
  tags = {
    Name        = "${var.project_name}-${var.environment}-dynamodb-table"
    Environment = var.environment
    Project     = var.project_name
  }
}