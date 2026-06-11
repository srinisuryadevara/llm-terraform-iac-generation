provider "aws" {
  region = var.aws_region
}

variable "aws_region" {
  type        = string
  description = "AWS Region"
}

variable "bucket_name" {
  type        = string
  description = "S3 Bucket Name"
}

variable "distribution_comment" {
  type        = string
  description = "CloudFront Distribution Comment"
}

variable "acm_certificate_arn" {
  type        = string
  description = "ACM Certificate ARN"
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

  tags = {
    Name        = "${var.bucket_name}-policy"
    Environment = "production"
  }
}

resource "aws_cloudfront_origin_access_identity" "this" {
  tags = {
    Name        = "cloudfront-oai"
    Environment = "production"
  }
}

resource "aws_cloudfront_distribution" "this" {
  comment = var.distribution_comment

  origin {
    domain_name = aws_s3_bucket.this.bucket_regional_domain_name
    origin_id   = "s3-origin"

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.this.cloudfront_access_identity_path
    }
  }

  enabled         = true
  is_ipv6_enabled = true

  aliases = ["example.com", "www.example.com"]

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "s3-origin"

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
    acm_certificate_arn = var.acm_certificate_arn
    ssl_support_method  = "sni-only"
  }

  tags = {
    Name        = var.distribution_comment
    Environment = "production"
  }
}

output "s3_bucket_id" {
  value       = aws_s3_bucket.this.id
  description = "S3 Bucket ID"
}

output "s3_bucket_name" {
  value       = aws_s3_bucket.this.bucket
  description = "S3 Bucket Name"
}

output "s3_bucket_arn" {
  value       = aws_s3_bucket.this.arn
  description = "S3 Bucket ARN"
}

output "cloudfront_distribution_id" {
  value       = aws_cloudfront_distribution.this.id
  description = "CloudFront Distribution ID"
}

output "cloudfront_distribution_domain_name" {
  value       = aws_cloudfront_distribution.this.domain_name
  description = "CloudFront Distribution Domain Name"
}

output "cloudfront_distribution_status" {
  value       = aws_cloudfront_distribution.this.status
  description = "CloudFront Distribution Status"
}