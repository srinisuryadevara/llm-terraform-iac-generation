terraform {
  required_version = ">= 1.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.47"
    }
  }

  backend "s3" {
    bucket         = var.tfstate_bucket
    key            = "terraform.tfstate"
    region         = var.tfstate_region
    dynamodb_table = var.tfstate_lock_table
    encrypt        = true
  }
}

resource "aws_dynamodb_table" "terraform_state_lock" {
  name         = var.tfstate_lock_table
  hash_key     = "LockID"
  billing_mode = "PAY_PER_REQUEST"

  attribute {
    name = "LockID"
    type = "S"
  }
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
locals {
  account_id  = data.aws_caller_identity.current.account_id
  region      = data.aws_region.current.name
  name_prefix = "kms-key"

  tags = {
    team     = "security"
    solution = "kms"
  }
}

resource "aws_kms_key" "this" {
  description             = var.description
  policy                  = var.policy
  enable_key_rotation     = var.enable_key_rotation
  deletion_window_in_days = var.deletion_window_in_days
  tags                    = local.tags
}

resource "aws_kms_alias" "this" {
  name          = var.alias
  target_key_id = aws_kms_key.this.key_id
}