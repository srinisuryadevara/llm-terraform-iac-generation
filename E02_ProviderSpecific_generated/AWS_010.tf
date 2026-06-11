provider "aws" {
  region = var.region
}

resource "aws_kms_key" "dynamodb" {
  description             = "KMS key for DynamoDB encryption"
  deletion_window_in_days = 10
}

resource "aws_kms_alias" "dynamodb" {
  name          = "alias/dynamodb-key"
  target_key_id = aws_kms_key.dynamodb.key_id
}

resource "aws_dynamodb_table" "example" {
  name           = var.table_name
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = var.hash_key
  attribute {
    name = var.hash_key
    type = "S"
  }
  attribute {
    name = var.sort_key
    type = "S"
  }
  global_secondary_index {
    name               = var.gsi_name
    hash_key           = var.sort_key
    projection_type    = "ALL"
  }
  point_in_time_recovery {
    enabled = true
  }
  server_side_encryption {
    enabled = true
    kms_key_arn = aws_kms_key.dynamodb.arn
  }
  tags = {
    Name        = var.table_name
    Environment = var.environment
  }
}