variable "bucket_name" {
  type        = string
  description = "Name of the S3 bucket"
}

variable "oai_iam_arn" {
  type        = string
  description = "ARN of the OAI IAM role"
}

variable "domain_name" {
  type        = string
  description = "Domain name for the CloudFront distribution"
}

variable "comment" {
  type        = string
  description = "Comment for the CloudFront distribution"
}

variable "is_ipv6_enabled" {
  type        = bool
  description = "Whether IPv6 is enabled for the CloudFront distribution"
}

variable "http_port" {
  type        = number
  description = "HTTP port for the custom origin"
}

variable "https_port" {
  type        = number
  description = "HTTPS port for the custom origin"
}

variable "origin_protocol_policy" {
  type        = string
  description = "Origin protocol policy for the custom origin"
}

variable "origin_ssl_protocols" {
  type        = list(string)
  description = "Origin SSL protocols for the custom origin"
}

variable "allowed_methods" {
  type        = list(string)
  description = "Allowed methods for the default cache behavior"
}

variable "cached_methods" {
  type        = list(string)
  description = "Cached methods for the default cache behavior"
}

variable "viewer_protocol_policy" {
  type        = string
  description = "Viewer protocol policy for the default cache behavior"
}

variable "compress" {
  type        = bool
  description = "Whether compression is enabled for the default cache behavior"
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
    origin_id   = "S3-${aws_s3_bucket.bucket.id}"

    s3_origin_config {
      origin_access_identity = "origin-access-identity/cloudfront/${aws_cloudfront_origin_access_identity.oai.id}"
    }
  }
  logging_config {
    bucket = aws_s3_bucket.access_logs.bucket_domain_name
    prefix = "AWSLogs/"
  }
  default_cache_behavior {
    allowed_methods          = var.allowed_methods
    cached_methods           = var.cached_methods
    target_origin_id         = "S3-${aws_s3_bucket.bucket.id}"
    viewer_protocol_policy   = var.viewer_protocol_policy
    compress                 = var.compress
  }
}

resource "aws_cloudfront_origin_access_identity" "oai" {
  comment = "OAI for S3 bucket"
}

resource "aws_s3_bucket" "access_logs" {
  bucket = "access-logs-bucket"
  acl    = "log-delivery-write"
}