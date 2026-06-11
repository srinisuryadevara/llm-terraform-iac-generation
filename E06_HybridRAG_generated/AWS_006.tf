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
  name           = var.table-name
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = var.hash-key
  attribute {
    name = var.hash-key
    type = "S"
  }
  attribute {
    name = var.range-key
    type = "S"
  }
  global_secondary_index {
    name               = var.gsi-name
    hash_key           = var.gsi-hash-key
    range_key          = var.gsi-range-key
    projection_type    = "INCLUDE"
    non_key_attributes = ["attribute1", "attribute2"]
  }
  point_in_time_recovery {
    enabled = true
  }
  server_side_encryption {
    enabled = true
    kms_key_arn = var.kms-key-arn
  }
  tags = {
    "Name" = var.table-name
  }
}