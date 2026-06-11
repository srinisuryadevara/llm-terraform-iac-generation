# Define the provider (AWS in this case)
provider "aws" {
  region = var.aws-region
}

# Create a DynamoDB table
resource "aws_dynamodb_table" "example" {
  name           = var.dynamodb-table-name
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = var.dynamodb-hash-key
  attribute {
    name = var.dynamodb-hash-key
    type = "S"
  }
  attribute {
    name = var.dynamodb-sort-key
    type = "S"
  }
  global_secondary_index {
    name               = var.dynamodb-gsi-name
    hash_key           = var.dynamodb-gsi-hash-key
    projection_type    = "INCLUDE"
    non_key_attributes = var.dynamodb-gsi-non-key-attributes
  }
  point_in_time_recovery {
    enabled = true
  }
  server_side_encryption {
    enabled = true
    kms_key_arn = var.dynamodb-kms-key-arn
  }
  tags = {
    "Name" = "DynamoDB Table with GSI and Encryption"
  }
}

# Create an IAM policy for the DynamoDB table
resource "aws_iam_policy" "dynamodb_policy" {
  name        = "${var.app_name}-dynamodb_policy"
  description = "IAM policy for DynamoDB table"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "dynamodb:BatchGetItem",
          "dynamodb:BatchWriteItem",
          "dynamodb:DeleteItem",
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:Query",
          "dynamodb:Scan",
          "dynamodb:UpdateItem"
        ]
        Effect   = "Allow"
        Resource = aws_dynamodb_table.example.arn
      }
    ]
  })
}

# Create an IAM role for the DynamoDB table
resource "aws_iam_role" "dynamodb_role" {
  name = "my-dynamodb-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "dynamodb.amazonaws.com"
        }
      }
    ]
  })
}

# Attach the DynamoDB policy to the DynamoDB role
resource "aws_iam_role_policy_attachment" "dynamodb_policy_attachment" {
  role       = aws_iam_role.dynamodb_role.name
  policy_arn = aws_iam_policy.dynamodb_policy.arn
}

variable "aws-region" {
  type = string
}

variable "dynamodb-table-name" {
  type = string
}

variable "dynamodb-hash-key" {
  type = string
}

variable "dynamodb-sort-key" {
  type = string
}

variable "dynamodb-gsi-name" {
  type = string
}

variable "dynamodb-gsi-hash-key" {
  type = string
}

variable "dynamodb-gsi-non-key-attributes" {
  type = list(string)
}

variable "dynamodb-kms-key-arn" {
  type = string
}

variable "app_name" {
  type = string
}