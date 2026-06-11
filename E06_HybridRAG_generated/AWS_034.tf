# S3 Bucket with Versioning, Server-Side Encryption, and Blocked Public Access

resource "aws_s3_bucket" "terraform_state" {
  bucket = var.bucket_name
}

# Enable versioning so we can see the full revision history of our state files
resource "aws_s3_bucket_versioning" "versioning_enabled" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Enable server-side encryption by default
resource "aws_s3_bucket_server_side_encryption_configuration" "aes256_encryption" {
  bucket = aws_s3_bucket.terraform_state.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Block public access to the S3 bucket
resource "aws_s3_bucket_public_access_block" "public_access_blocked" {
  bucket = aws_s3_bucket.terraform_state.id
  block_public_acls   = true
  block_public_policy = true
  ignore_public_acls  = true
  restrict_public_buckets = true
}

# Lifecycle configuration to prevent accidental deletion
resource "aws_s3_bucket_lifecycle_configuration" "lifecycle_config" {
  bucket = aws_s3_bucket.terraform_state.id
  rule {
    id = "prevent_deletion"
    status = "Enabled"
    filter {}
    expiration {
      days = 3650
    }
    noncurrent_version_expiration {
      days = 3650
    }
  }
}

# Output the S3 bucket ARN
output "s3_bucket_arn" {
  value = aws_s3_bucket.terraform_state.arn
}

variable "bucket_name" {
  type        = string
  description = "The name of the S3 bucket"
}