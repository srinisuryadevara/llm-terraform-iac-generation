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