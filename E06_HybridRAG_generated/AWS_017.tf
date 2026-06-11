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

variable "comment" {
  type        = string
  description = "CloudFront Distribution Comment"
}

variable "is_ipv6_enabled" {
  type        = bool
  description = "Is IPv6 Enabled"
}

variable "http_port" {
  type        = number
  description = "HTTP Port"
}

variable "https_port" {
  type        = number
  description = "HTTPS Port"
}

variable "origin_protocol_policy" {
  type        = string
  description = "Origin Protocol Policy"
}

variable "origin_ssl_protocols" {
  type        = list(string)
  description = "Origin SSL Protocols"
}

variable "allowed_methods" {
  type        = list(string)
  description = "Allowed Methods"
}

variable "cached_methods" {
  type        = list(string)
  description = "Cached Methods"
}

variable "viewer_protocol_policy" {
  type        = string
  description = "Viewer Protocol Policy"
}

variable "compress" {
  type        = bool
  description = "Compress"
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
        Sid       = "AllowCloudFrontRead"
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
  is_ipv6_enabled = var.is_ipv6_enabled
  comment         = var.comment
  aliases         = [var.domain_name]
  origin {
    domain_name = aws_s3_bucket.bucket.bucket_regional_domain_name
    origin_id   = var.bucket_name

    s3_origin_config {
      origin_access_identity = var.oai_iam_arn
    }
  }
  logging_config {
    bucket = aws_s3_bucket.bucket.bucket_domain_name
    prefix = "AWSLogs/"
  }
  default_cache_behavior {
    allowed_methods          = var.allowed_methods
    cached_methods           = var.cached_methods
    target_origin_id         = var.bucket_name
    viewer_protocol_policy   = var.viewer_protocol_policy
    compress                 = var.compress
  }
}

resource "aws_cloudfront_origin_access_identity" "oai" {
  comment = "OAI for S3 Bucket"
}