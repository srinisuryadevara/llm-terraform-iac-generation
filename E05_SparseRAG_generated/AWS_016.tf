variable "domain" {
  type        = string
  description = "Domain name of the S3 bucket"
}

variable "is_ipv6_enabled" {
  type        = bool
  description = "Whether IPv6 is enabled for the CloudFront distribution"
}

variable "comment" {
  type        = string
  description = "Comment for the CloudFront distribution"
}

variable "http_port" {
  type        = number
  description = "HTTP port for the CloudFront distribution"
}

variable "https_port" {
  type        = number
  description = "HTTPS port for the CloudFront distribution"
}

variable "origin_protocol_policy" {
  type        = string
  description = "Origin protocol policy for the CloudFront distribution"
}

variable "origin_ssl_protocols" {
  type        = list(string)
  description = "Origin SSL protocols for the CloudFront distribution"
}

variable "allowed_methods" {
  type        = list(string)
  description = "Allowed methods for the CloudFront distribution"
}

variable "cached_methods" {
  type        = list(string)
  description = "Cached methods for the CloudFront distribution"
}

variable "viewer_protocol_policy" {
  type        = string
  description = "Viewer protocol policy for the CloudFront distribution"
}

variable "compre" {
  type        = bool
  description = "Whether compression is enabled for the CloudFront distribution"
}

provider "aws" {
  alias  = "acm"
  region = "us-east-1"
}

resource "aws_cloudfront_origin_access_identity" "static_site" {
  comment = var.domain
}

data "aws_iam_policy_document" "read_static_site_bucket" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.static_site.arn}/*"]

    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.static_site.iam_arn]
    }
  }

  statement {
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.static_site.arn]

    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.static_site.iam_arn]
    }
  }
}

resource "aws_s3_bucket" "static_site" {
  bucket = var.domain
}

resource "aws_s3_bucket_acl" "static_site" {
  bucket = aws_s3_bucket.static_site.id
  acl    = "private"
}

resource "aws_s3_bucket_policy" "static_site" {
  bucket = aws_s3_bucket.static_site.id
  policy = data.aws_iam_policy_document.read_static_site_bucket.json
}

resource "aws_cloudfront_distribution" "this" {
  enabled         = true
  is_ipv6_enabled = var.is_ipv6_enabled
  comment         = var.comment
  aliases         = [var.domain]
  origin {
    domain_name = aws_s3_bucket.static_site.bucket_regional_domain_name
    origin_id   = aws_s3_bucket.static_site.id

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.static_site.cloudfront_access_identity_path
    }
  }
  logging_config {
    bucket = aws_s3_bucket.static_site.bucket_domain_name
    prefix = "AWSLogs/"
  }
  default_cache_behavior {
    allowed_methods          = var.allowed_methods
    cached_methods           = var.cached_methods
    target_origin_id         = aws_s3_bucket.static_site.id
    viewer_protocol_policy   = var.viewer_protocol_policy
    compress                 = var.compre
    min_ttl                  = 0
    default_ttl              = 3600
    max_ttl                  = 86400
  }
}