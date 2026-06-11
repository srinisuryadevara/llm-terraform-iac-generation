provider "aws" {
  region = var.region
}

variable "region" {
  type        = string
  description = "AWS Region"
}

variable "domain" {
  type        = string
  description = "Domain name for S3 bucket"
}

variable "bucket_name" {
  type        = string
  description = "Name of the S3 bucket"
}

variable "oai_comment" {
  type        = string
  description = "Comment for the CloudFront Origin Access Identity"
}

variable "distribution_comment" {
  type        = string
  description = "Comment for the CloudFront distribution"
}

variable "enabled" {
  type        = bool
  description = "Whether the CloudFront distribution is enabled"
  default     = true
}

variable "is_ipv6_enabled" {
  type        = bool
  description = "Whether IPv6 is enabled for the CloudFront distribution"
  default     = false
}

variable "aliases" {
  type        = list(string)
  description = "List of domain names for the CloudFront distribution"
}

variable "http_port" {
  type        = number
  description = "HTTP port for the CloudFront distribution"
  default     = 80
}

variable "https_port" {
  type        = number
  description = "HTTPS port for the CloudFront distribution"
  default     = 443
}

variable "origin_protocol_policy" {
  type        = string
  description = "Origin protocol policy for the CloudFront distribution"
  default     = "match-viewer"
}

variable "origin_ssl_protocols" {
  type        = list(string)
  description = "List of SSL protocols for the CloudFront distribution"
  default     = ["TLSv1", "TLSv1.1", "TLSv1.2"]
}

variable "viewer_protocol_policy" {
  type        = string
  description = "Viewer protocol policy for the CloudFront distribution"
  default     = "allow-all"
}

variable "allowed_methods" {
  type        = list(string)
  description = "List of allowed methods for the CloudFront distribution"
  default     = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
}

variable "cached_methods" {
  type        = list(string)
  description = "List of cached methods for the CloudFront distribution"
  default     = ["GET", "HEAD", "OPTIONS"]
}

variable "compress" {
  type        = bool
  description = "Whether to compress the content for the CloudFront distribution"
  default     = true
}

resource "aws_s3_bucket" "this" {
  bucket = var.bucket_name
  acl    = "private"
}

resource "aws_s3_bucket_policy" "this" {
  bucket = aws_s3_bucket.this.id
  policy = data.aws_iam_policy_document.this.json
}

data "aws_iam_policy_document" "this" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.this.arn}/*"]

    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.this.iam_arn]
    }
  }

  statement {
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.this.arn]

    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.this.iam_arn]
    }
  }
}

resource "aws_cloudfront_origin_access_identity" "this" {
  comment = var.oai_comment
}

resource "aws_cloudfront_distribution" "this" {
  enabled         = var.enabled
  is_ipv6_enabled = var.is_ipv6_enabled
  comment         = var.distribution_comment
  aliases         = var.aliases

  origin {
    domain_name = aws_s3_bucket.this.bucket_regional_domain_name
    origin_id   = aws_s3_bucket.this.id

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.this.cloudfront_access_identity_path
    }
  }

  default_cache_behavior {
    allowed_methods          = var.allowed_methods
    cached_methods           = var.cached_methods
    target_origin_id         = aws_s3_bucket.this.id
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