provider "aws" {
  region = var.region
}

variable "region" {
  type        = string
  description = "AWS Region"
}

variable "bucket_name" {
  type        = string
  description = "S3 Bucket Name"
}

variable "oai_iam_arn" {
  type        = string
  description = "OAI IAM ARN"
}

variable "domain_name" {
  type        = string
  description = "Domain Name"
}

variable "http_port" {
  type        = number
  default     = 80
}

variable "https_port" {
  type        = number
  default     = 443
}

variable "origin_protocol_policy" {
  type        = string
  default     = "match-viewer"
}

variable "origin_ssl_protocols" {
  type        = list(string)
  default     = ["TLSv1", "TLSv1.1", "TLSv1.2"]
}

variable "allowed_methods" {
  type        = list(string)
  default     = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
}

variable "cached_methods" {
  type        = list(string)
  default     = ["GET", "HEAD", "OPTIONS"]
}

variable "viewer_protocol_policy" {
  type        = string
  default     = "allow-all"
}

variable "compress" {
  type        = bool
  default     = true
}

resource "aws_s3_bucket" "bucket" {
  bucket = var.bucket_name
  acl    = "private"

  versioning {
    enabled = true
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_policy" "bucket_policy" {
  bucket = aws_s3_bucket.bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "Allow CloudFront read"
        Effect    = "Allow"
        Principal = {
          AWS = var.oai_iam_arn
        }
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.bucket.arn}/*"
      },
    ]
  })
}

resource "aws_cloudfront_distribution" "distribution" {
  enabled         = true
  is_ipv6_enabled = true
  comment         = "CloudFront Distribution"

  aliases = [var.domain_name]

  origin {
    domain_name = aws_s3_bucket.bucket.bucket_regional_domain_name
    origin_id   = "S3-${aws_s3_bucket.bucket.id}"

    s3_origin_config {
      origin_access_identity = var.oai_iam_arn
    }
  }

  default_cache_behavior {
    allowed_methods          = var.allowed_methods
    cached_methods           = var.cached_methods
    target_origin_id         = "S3-${aws_s3_bucket.bucket.id}"
    viewer_protocol_policy   = var.viewer_protocol_policy
    compress                 = var.compress
    min_ttl                  = 0
    default_ttl              = 3600
    max_ttl                  = 86400
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}