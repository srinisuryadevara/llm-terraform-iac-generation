provider "aws" {
  region = var.aws_region
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
  global_secondary_index {
    name               = "sort_key_index"
    hash_key           = "sort_key"
    projection_type    = "INCLUDE"
    non_key_attributes = ["attribute1", "attribute2"]
  }
  point_in_time_recovery {
    enabled = true
  }
  server_side_encryption {
    enabled     = true
    kms_key_arn = aws_kms_key.example.arn
  }
  tags = {
    Name        = var.dynamodb_table_name
    Environment = var.environment
  }
}

resource "aws_kms_key" "example" {
  description             = "KMS key for DynamoDB table encryption"
  deletion_window_in_days = 10
}

resource "aws_kms_alias" "example" {
  name          = "alias/dynamodb-key"
  target_key_id = aws_kms_key.example.key_id
}