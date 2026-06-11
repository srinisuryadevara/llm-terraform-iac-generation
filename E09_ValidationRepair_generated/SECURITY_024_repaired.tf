provider "aws" {
  region = var.aws_region
}

resource "aws_kms_key" "cloudtrail" {
  description             = "KMS key for CloudTrail"
  deletion_window_in_days = 10
  tags = {
    Name        = "cloudtrail-kms-key"
    Environment = "production"
  }
}

resource "aws_kms_alias" "cloudtrail" {
  name          = "alias/cloudtrail"
  target_key_id = aws_kms_key.cloudtrail.key_id
  tags = {
    Name        = "cloudtrail-kms-alias"
    Environment = "production"
  }
}

resource "aws_s3_bucket" "cloudtrail" {
  bucket        = var.cloudtrail_bucket_name
  force_destroy = true
  tags = {
    Name        = "cloudtrail-s3-bucket"
    Environment = "production"
  }
}

resource "aws_s3_bucket_policy" "cloudtrail" {
  bucket = aws_s3_bucket.cloudtrail.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AWSCloudTrailWrite"
        Effect    = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.cloudtrail.arn}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      },
      {
        Sid       = "AWSCloudTrailRead"
        Effect    = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.cloudtrail.arn}/*"
      },
    ]
  })
  tags = {
    Name        = "cloudtrail-s3-bucket-policy"
    Environment = "production"
  }
}

resource "aws_cloudtrail" "cloudtrail" {
  name                          = var.cloudtrail_name
  s3_bucket_name                = aws_s3_bucket.cloudtrail.id
  s3_key_prefix                 = var.cloudtrail_key_prefix
  include_global_service_events = true
  is_multi_region_trail         = true
  is_organization_trail         = false
  enable_log_file_validation    = true
  kms_key_id                    = aws_kms_key.cloudtrail.key_id
  tags = {
    Name        = "cloudtrail"
    Environment = "production"
  }
}

variable "aws_region" {
  type        = string
  description = "AWS region"
}

variable "cloudtrail_bucket_name" {
  type        = string
  description = "CloudTrail S3 bucket name"
}

variable "cloudtrail_name" {
  type        = string
  description = "CloudTrail name"
}

variable "cloudtrail_key_prefix" {
  type        = string
  description = "CloudTrail S3 key prefix"
}

output "cloudtrail_name" {
  value       = aws_cloudtrail.cloudtrail.name
  description = "CloudTrail name"
}

output "cloudtrail_arn" {
  value       = aws_cloudtrail.cloudtrail.arn
  description = "CloudTrail ARN"
}

output "cloudtrail_s3_bucket_name" {
  value       = aws_s3_bucket.cloudtrail.id
  description = "CloudTrail S3 bucket name"
}

output "cloudtrail_s3_bucket_arn" {
  value       = aws_s3_bucket.cloudtrail.arn
  description = "CloudTrail S3 bucket ARN"
}

output "cloudtrail_kms_key_id" {
  value       = aws_kms_key.cloudtrail.key_id
  description = "CloudTrail KMS key ID"
}

output "cloudtrail_kms_key_arn" {
  value       = aws_kms_key.cloudtrail.arn
  description = "CloudTrail KMS key ARN"
}