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

resource "aws_s3_bucket" "terraform_state" {
  bucket        = var.bucket-name
  force_destroy = var.force_destroy

  lifecycle {
    prevent_destroy = var.prevent_destroy
  }

  tags = {
    "Name" = var.bucket-name
  }
}

resource "aws_s3_bucket_versioning" "versioning_enabled" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "aes256_encryption" {
  bucket = aws_s3_bucket.terraform_state.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = var.bucket-encryption
    }
  }
}

resource "aws_s3_bucket_public_access_block" "block_public_access" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls   = true
  block_public_policy = true
  ignore_public_acls  = true
  restrict_public_buckets = true
}

variable "region" {
  type        = string
  description = "AWS Region"
}

variable "bucket-name" {
  type        = string
  description = "S3 Bucket Name"
}

variable "force_destroy" {
  type        = bool
  description = "Force destroy S3 Bucket"
  default     = false
}

variable "prevent_destroy" {
  type        = bool
  description = "Prevent destroy S3 Bucket"
  default     = false
}

variable "bucket-encryption" {
  type        = string
  description = "S3 Bucket Encryption Algorithm"
  default     = "AES256"
}