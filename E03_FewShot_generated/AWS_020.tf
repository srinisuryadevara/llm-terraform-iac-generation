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
    enabled = true
  }
  tags = {
    Environment = var.environment
  }
}

resource "aws_kms_key" "dynamodb" {
  description             = "KMS key for DynamoDB encryption"
  deletion_window_in_days = 10
}

resource "aws_kms_alias" "dynamodb" {
  name          = "alias/dynamodb-kms-key"
  target_key_id = aws_kms_key.dynamodb.key_id
}

resource "aws_dynamodb_table_item" "example" {
  table_name = aws_dynamodb_table.example.name
  item       = "{\"id\":{\"S\":\"1\"},\"sort_key\":{\"S\":\"sort_key_1\"},\"attribute1\":{\"S\":\"attribute1_value\"},\"attribute2\":{\"S\":\"attribute2_value\"}}"
}