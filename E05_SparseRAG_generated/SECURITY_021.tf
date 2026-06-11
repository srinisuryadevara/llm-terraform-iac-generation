variable "kms_key_arn" {
  type        = string
  sensitive   = true
}

variable "bucket_name" {
  type        = string
}

variable "tags" {
  type        = map(string)
  default     = {}
}

resource "aws_s3_bucket" "private_bucket" {
  bucket = var.bucket_name

  tags = merge({ Name = var.bucket_name }, var.tags)
}

resource "aws_s3_bucket_public_access_block" "private_bucket" {
  bucket = aws_s3_bucket.private_bucket.id

  block_public_acls   = true
  block_public_policy = true
  ignore_public_acls  = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "private_bucket" {
  bucket = aws_s3_bucket.private_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = var.kms_key_arn
      sse_algorithm     = "aws:kms"
    }
  }
}