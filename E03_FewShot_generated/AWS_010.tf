provider "aws" {
  region = var.aws_region
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
    name = var.range_key
    type = "S"
  }
  global_secondary_index {
    name               = var.gsi_name
    hash_key           = var.gsi_hash_key
    range_key          = var.gsi_range_key
    projection_type    = "INCLUDE"
    non_key_attributes = var.gsi_non_key_attributes
  }
  point_in_time_recovery {
    enabled = true
  }
  server_side_encryption {
    enabled = true
  }
  tags = var.tags
}

variable "aws_region" {
  type        = string
  sensitive   = true
}

variable "table_name" {
  type        = string
  sensitive   = true
}

variable "hash_key" {
  type        = string
  sensitive   = true
}

variable "range_key" {
  type        = string
  sensitive   = true
}

variable "gsi_name" {
  type        = string
  sensitive   = true
}

variable "gsi_hash_key" {
  type        = string
  sensitive   = true
}

variable "gsi_range_key" {
  type        = string
  sensitive   = true
}

variable "gsi_non_key_attributes" {
  type        = list(string)
  sensitive   = true
}

variable "tags" {
  type        = map(string)
  sensitive   = true
}