provider "aws" {
  region = var.region
}

variable "region" {
  type        = string
  description = "AWS Region"
}

variable "domain" {
  type        = string
  description = "Domain name"
}

variable "bucket_name" {
  type        = string
  description = "S3 Bucket name"
}

variable "oai_comment" {
  type        = string
  description = "OAI comment"
}

variable "distribution_comment" {
  type        = string
  description = "CloudFront distribution comment"
}

variable "aliases" {
  type        = list(string)
  description = "CloudFront distribution aliases"
}

variable "acm_certificate_arn" {
  type        = string
  description = "ACM certificate ARN"
}

variable "default_root_object" {
  type        = string
  description = "Default root object"
}

variable "enabled" {
  type        = bool
  description = "CloudFront distribution enabled"
}

variable "is_ipv6_enabled" {
  type        = bool
  description = "IPv6 enabled"
}

variable "price_class" {
  type        = string
  description = "Price class"
}

variable "viewer_protocol_policy" {
  type        = string
  description = "Viewer protocol policy"
}

variable "allowed_methods" {
  type        = list(string)
  description = "Allowed methods"
}

variable "cached_methods" {
  type        = list(string)
  description = "Cached methods"
}

variable "compress" {
  type        = bool
  description = "Compress"
}

variable "default_ttl" {
  type        = number
  description = "Default TTL"
}

variable "max_ttl" {
  type        = number
  description = "Max TTL"
}

variable "min_ttl" {
  type        = number
  description = "Min TTL"
}

variable "smooth_streaming" {
  type        = bool
  description = "Smooth streaming"
}

variable "web_acl_id" {
  type        = string
  description = "Web ACL ID"
}

resource "aws_cloudfront_origin_access_identity" "this" {
  comment = var.oai_comment
}

data "aws_iam_policy_document" "s3_policy" {
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

resource "aws_s3_bucket" "this" {
  bucket = var.bucket_name
}

resource "aws_s3_bucket_acl" "this" {
  bucket = aws_s3_bucket.this.id
  acl    = "private"
}

resource "aws_s3_bucket_policy" "this" {
  bucket = aws_s3_bucket.this.id
  policy = data.aws_iam_policy_document.s3_policy.json
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
    allowed_methods  = var.allowed_methods
    cached_methods   = var.cached_methods
    target_origin_id = aws_s3_bucket.this.id
    viewer_protocol_policy = var.viewer_protocol_policy
    compress                 = var.compress
    default_ttl             = var.default_ttl
    max_ttl                 = var.max_ttl
    min_ttl                 = var.min_ttl
    smooth_streaming       = var.smooth_streaming
  }
  viewer_certificate {
    acm_certificate_arn = var.acm_certificate_arn
    ssl_support_method  = "sni-only"
  }
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
  web_acl_id = var.web_acl_id
}