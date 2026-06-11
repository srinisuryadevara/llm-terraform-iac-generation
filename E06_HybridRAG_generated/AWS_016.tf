variable "bucket_name" {
  type        = string
  description = "The name of the S3 bucket"
}

variable "oai_iam_arn" {
  type        = string
  description = "The ARN of the OAI IAM role"
}

variable "domain_name" {
  type        = string
  description = "The domain name for the CloudFront distribution"
}

variable "comment" {
  type        = string
  description = "The comment for the CloudFront distribution"
}

variable "is_ipv6_enabled" {
  type        = bool
  description = "Whether to enable IPv6 for the CloudFront distribution"
}

variable "http_port" {
  type        = number
  description = "The HTTP port for the CloudFront distribution"
}

variable "https_port" {
  type        = number
  description = "The HTTPS port for the CloudFront distribution"
}

variable "origin_protocol_policy" {
  type        = string
  description = "The origin protocol policy for the CloudFront distribution"
}

variable "origin_ssl_protocols" {
  type        = list(string)
  description = "The origin SSL protocols for the CloudFront distribution"
}

variable "allowed_methods" {
  type        = list(string)
  description = "The allowed methods for the CloudFront distribution"
}

variable "cached_methods" {
  type        = list(string)
  description = "The cached methods for the CloudFront distribution"
}

variable "viewer_protocol_policy" {
  type        = string
  description = "The viewer protocol policy for the CloudFront distribution"
}

variable "waf_enable" {
  type        = bool
  description = "Whether to enable WAF for the CloudFront distribution"
}

variable "compress" {
  type        = bool
  description = "Whether to compress the CloudFront distribution"
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
  default_cache_behavior {
    allowed_methods          = var.allowed_methods
    cached_methods           = var.cached_methods
    target_origin_id         = var.bucket_name
    viewer_protocol_policy   = var.viewer_protocol_policy
    compress                 = var.compress
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

resource "aws_cloudfront_origin_access_identity" "oai" {
  comment = "OAI for ${var.bucket_name}"
}