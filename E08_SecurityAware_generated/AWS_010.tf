provider "aws" {
  region = var.region
}

variable "region" {
  type        = string
  description = "AWS Region"
}

variable "project" {
  type        = string
  description = "Project Name"
}

variable "environment" {
  type        = string
  description = "Environment Name"
}

variable "table_name" {
  type        = string
  description = "DynamoDB Table Name"
}

variable "read_capacity_units" {
  type        = number
  description = "Read Capacity Units"
}

variable "write_capacity_units" {
  type        = number
  description = "Write Capacity Units"
}

variable "attribute_name" {
  type        = string
  description = "Attribute Name"
}

variable "attribute_type" {
  type        = string
  description = "Attribute Type"
}

variable "gsi_name" {
  type        = string
  description = "GSI Name"
}

variable "gsi_projection_type" {
  type        = string
  description = "GSI Projection Type"
}

resource "aws_dynamodb_table" "example" {
  name           = var.table_name
  read_capacity_units  = var.read_capacity_units
  write_capacity_units = var.write_capacity_units
  hash_key       = var.attribute_name
  attribute {
    name = var.attribute_name
    type = var.attribute_type
  }
  global_secondary_index {
    name               = var.gsi_name
    hash_key           = var.attribute_name
    projection_type    = var.gsi_projection_type
    read_capacity_units = var.read_capacity_units
    write_capacity_units = var.write_capacity_units
  }
  point_in_time_recovery {
    enabled = true
  }
  server_side_encryption {
    enabled = true
  }
  tags = {
    Project     = var.project
    Environment = var.environment
  }
}

resource "aws_kms_key" "example" {
  description             = "KMS Key for DynamoDB"
  deletion_window_in_days = 10
  tags = {
    Project     = var.project
    Environment = var.environment
  }
}

resource "aws_kms_alias" "example" {
  name          = "alias/dynamodb-key"
  target_key_id = aws_kms_key.example.key_id
}

resource "aws_dynamodb_table_item" "example" {
  table_name = aws_dynamodb_table.example.name
  item       = "{\"${var.attribute_name}\": {\"S\": \"example\"}}"
}