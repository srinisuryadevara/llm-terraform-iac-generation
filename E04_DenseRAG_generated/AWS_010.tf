terraform {
  required_version = ">= 1.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.47"
    }
  }
}

provider "aws" {
  region = var.aws-region
}

resource "aws_dynamodb_table" "example_table" {
  name           = var.dynamodb-table-name
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
    name               = "example_gsi"
    hash_key           = "sort_key"
    projection_type    = "ALL"
  }
  point_in_time_recovery {
    enabled = true
  }
  server_side_encryption {
    enabled = true
  }
  tags = {
    "Name" = "DynamoDB Table with GSI, PITR, and Encryption"
  }
}