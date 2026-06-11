provider "aws" {
  region = var.region
}

resource "aws_kms_key" "dynamodb_key" {
  description             = "KMS key for DynamoDB encryption"
  deletion_window_in_days = 10
}

resource "aws_kms_alias" "dynamodb_key_alias" {
  name          = "alias/dynamodb-key"
  target_key_id = aws_kms_key.dynamodb_key.key_id
}

resource "aws_dynamodb_table" "example_table" {
  name           = var.table_name
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
    projection_type    = "ALL"
  }
  point_in_time_recovery {
    enabled = true
  }
  server_side_encryption {
    enabled     = true
    kms_key_arn = aws_kms_key.dynamodb_key.arn
  }
  tags = {
    Name        = "example-dynamodb-table"
    Environment = "example"
  }
}