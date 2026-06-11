variable "bucket-name" {
  type        = string
  description = "Name of the S3 bucket"
}

variable "bucket-encryption" {
  type        = string
  default     = "AES256"
  description = "Encryption algorithm for the S3 bucket"
}

variable "kms_key_arn" {
  type        = string
  description = "ARN of the KMS key for encryption"
}

resource "aws_s3_bucket" "terraform_state" {
  bucket = var.bucket-name
}

resource "aws_s3_bucket_versioning" "versioning_enabled" {
  bucket = var.bucket-name
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "aes256_encryption" {
  bucket = var.bucket-name
  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = var.kms_key_arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "block_public_access" {
  bucket = var.bucket-name

  block_public_acls   = true
  block_public_policy = true
  ignore_public_acls  = true
  restrict_public_buckets = true
}