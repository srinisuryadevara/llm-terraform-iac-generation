provider "aws" {
  region = var.aws_region
}

variable "aws_region" {
  type        = string
  sensitive   = true
}

variable "bucket_name" {
  type        = string
  sensitive   = true
}

variable "distribution_name" {
  type        = string
  sensitive   = true
}

variable "oai_iam_user_name" {
  type        = string
  sensitive   = true
}

variable "oai_iam_user_path" {
  type        = string
  sensitive   = true
}

resource "aws_s3_bucket" "this" {
  bucket = var.bucket_name
  acl    = "private"

  versioning {
    enabled = true
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  tags = {
    Name        = var.bucket_name
    Environment = "production"
  }
}

resource "aws_s3_bucket_policy" "this" {
  bucket = aws_s3_bucket.this.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowCloudFrontRead"
        Effect    = "Allow"
        Principal = {
          AWS = aws_cloudfront_origin_access_identity.this.iam_arn
        }
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.this.arn}/*"
      },
    ]
  })
}

resource "aws_cloudfront_origin_access_identity" "this" {
  comment = var.oai_iam_user_name
}

resource "aws_iam_user" "this" {
  name          = var.oai_iam_user_name
  path          = var.oai_iam_user_path

  tags = {
    Name        = var.oai_iam_user_name
    Environment = "production"
  }
}

resource "aws_iam_access_key" "this" {
  user = aws_iam_user.this.name
}

resource "aws_iam_user_policy" "this" {
  name   = "cloudfront-oai-policy"
  user   = aws_iam_user.this.name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowCloudFrontRead"
        Effect    = "Allow"
        Action    = "cloudfront:GetDistributionConfig"
        Resource = "*"
      },
    ]
  })
}

resource "aws_cloudfront_distribution" "this" {
  enabled = true

  origin {
    domain_name = aws_s3_bucket.this.bucket_regional_domain_name
    origin_id   = var.distribution_name

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.this.cloudfront_access_identity_path
    }
  }

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = var.distribution_name

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "allow-all"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = {
    Name        = var.distribution_name
    Environment = "production"
  }
}

output "s3_bucket_id" {
  value       = aws_s3_bucket.this.id
  description = "The ID of the S3 bucket"
}

output "s3_bucket_arn" {
  value       = aws_s3_bucket.this.arn
  description = "The ARN of the S3 bucket"
}

output "cloudfront_distribution_id" {
  value       = aws_cloudfront_distribution.this.id
  description = "The ID of the CloudFront distribution"
}

output "cloudfront_distribution_arn" {
  value       = aws_cloudfront_distribution.this.arn
  description = "The ARN of the CloudFront distribution"
}

output "cloudfront_distribution_domain_name" {
  value       = aws_cloudfront_distribution.this.domain_name
  description = "The domain name of the CloudFront distribution"
}

output "iam_user_name" {
  value       = aws_iam_user.this.name
  description = "The name of the IAM user"
}

output "iam_user_arn" {
  value       = aws_iam_user.this.arn
  description = "The ARN of the IAM user"
}

output "iam_access_key_id" {
  value       = aws_iam_access_key.this.id
  description = "The ID of the IAM access key"
}

output "iam_access_key_secret" {
  value       = aws_iam_access_key.this.secret
  sensitive   = true
  description = "The secret of the IAM access key"
}