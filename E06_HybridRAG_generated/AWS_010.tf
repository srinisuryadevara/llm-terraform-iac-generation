terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.14.0"
    }
  }
}

provider "aws" {
  region = var.region
}

resource "aws_dynamodb_table" "example" {
  name           = var.dynamodb-table
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
    name               = "GSI_Example"
    hash_key           = "sort_key"
    projection_type    = "ALL"
  }
  point_in_time_recovery {
    enabled = true
  }
  server_side_encryption {
    enabled = true
    kms_key_arn = var.kms_key_arn
  }
  tags = {
    "Name" = "DynamoDB Table with GSI and PITR"
  }
}

resource "aws_kms_key" "example" {
  description             = "KMS key for DynamoDB encryption"
  deletion_window_in_days = 10
}

resource "aws_kms_alias" "example" {
  name          = "alias/dynamodb-kms-key"
  target_key_id = aws_kms_key.example.key_id
}