variable "domain" {
  type        = string
  description = "Domain name for the S3 bucket"
}

variable "is_ipv6_enabled" {
  type        = bool
  default     = true
  description = "Whether to enable IPv6 for the CloudFront distribution"
}

variable "comment" {
  type        = string
  default     = "CloudFront distribution for S3 bucket"
  description = "Comment for the CloudFront distribution"
}

variable "http_port" {
  type        = number
  default     = 80
  description = "HTTP port for the CloudFront distribution"
}

variable "https_port" {
  type        = number
  default     = 443
  description = "HTTPS port for the CloudFront distribution"
}

variable "origin_protocol_policy" {
  type        = string
  default     = "match-viewer"
  description = "Origin protocol policy for the CloudFront distribution"
}

variable "origin_ssl_protocols" {
  type        = list(string)
  default     = ["TLSv1", "TLSv1.1", "TLSv1.2"]
  description = "Origin SSL protocols for the CloudFront distribution"
}

variable "allowed_methods" {
  type        = list(string)
  default     = ["GET", "HEAD", "OPTIONS"]
  description = "Allowed methods for the CloudFront distribution"
}

variable "cached_methods" {
  type        = list(string)
  default     = ["GET", "HEAD"]
  description = "Cached methods for the CloudFront distribution"
}

variable "viewer_protocol_policy" {
  type        = string
  default     = "allow-all"
  description = "Viewer protocol policy for the CloudFront distribution"
}

variable "compre" {
  type        = bool
  default     = true
  description = "Whether to compress the CloudFront distribution"
}

provider "aws" {
  alias  = "acm"
  region = "us-east-1"
}

resource "aws_cloudfront_origin_access_identity" "this" {
  comment = "access-identity-${var.domain}"
}

data "aws_iam_policy_document" "this" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["arn:aws:s3:::${var.domain}/*"]

    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.this.iam_arn]
    }
  }

  statement {
    actions   = ["s3:ListBucket"]
    resources = ["arn:aws:s3:::${var.domain}"]

    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.this.iam_arn]
    }
  }
}

resource "aws_s3_bucket" "this" {
  bucket = var.domain
}

resource "aws_s3_bucket_acl" "this" {
  bucket = aws_s3_bucket.this.id
  acl    = "private"
}

resource "aws_s3_bucket_policy" "this" {
  bucket = aws_s3_bucket.this.id
  policy = data.aws_iam_policy_document.this.json
}

resource "aws_cloudfront_distribution" "this" {
  enabled         = true
  is_ipv6_enabled = var.is_ipv6_enabled
  comment         = var.comment
  aliases         = [var.domain]

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
    compress                 = var.compre
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