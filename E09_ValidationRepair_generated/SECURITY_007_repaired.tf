variable "kms_key_arn" {
  type        = string
  sensitive   = true
}

resource "aws_s3_bucket" "example" {
  bucket = "example-bucket"
  acl    = "private"

  versioning {
    enabled = true
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = var.kms_key_arn
        sse_algorithm     = "aws:kms"
      }
    }
  }

  tags = {
    Name        = "example-bucket"
    Environment = "example"
  }
}

resource "aws_s3_bucket_public_access_block" "example" {
  bucket = aws_s3_bucket.example.id

  block_public_acls   = true
  block_public_policy = true
  ignore_public_acls  = true
  restrict_public_buckets = true

  tags = {
    Name        = "example-bucket-public-access-block"
    Environment = "example"
  }
}

output "s3_bucket_id" {
  value       = aws_s3_bucket.example.id
  description = "The ID of the S3 bucket"
}

output "s3_bucket_arn" {
  value       = aws_s3_bucket.example.arn
  description = "The ARN of the S3 bucket"
}

output "kms_key_arn" {
  value       = var.kms_key_arn
  sensitive   = true
  description = "The ARN of the KMS key used for encryption"
}