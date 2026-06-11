variable "bucket_name" {
  type = string
}

variable "origin_domain_name" {
  type = string
}

variable "origin_path" {
  type = string
}

variable "origin_id" {
  type = string
}

variable "distribution_comment" {
  type = string
}

variable "aliases" {
  type = list(string)
}

variable "default_root_object" {
  type = string
}

variable "enabled" {
  type = bool
}

variable "is_ipv6_enabled" {
  type = bool
}

variable "default_cache_behavior_allowed_methods" {
  type = list(string)
}

variable "default_cache_behavior_cached_methods" {
  type = list(string)
}

variable "default_cache_behavior_target_origin_id" {
  type = string
}

variable "default_cache_behavior_forwarder_query_string" {
  type = bool
}

variable "default_cache_behavior_forwarder_cookies" {
  type = string
}

variable "viewer_protocol_policy" {
  type = string
}

variable "min_ttl" {
  type = number
}

variable "default_ttl" {
  type = number
}

variable "max_ttl" {
  type = number
}

variable "compress" {
  type = bool
}

variable "region" {
  type = string
}

resource "aws_s3_bucket" "bucket" {
  bucket        = var.bucket_name
  acl           = "private"
  region        = var.region

  versioning {
    enabled = true
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_policy" "policy" {
  bucket = aws_s3_bucket.bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "1"
        Effect    = "Allow"
        Principal = {
          AWS = aws_cloudfront_origin_access_identity.oai.iam_arn
        }
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.bucket.arn}/*"
      },
    ]
  })
}

resource "aws_cloudfront_origin_access_identity" "oai" {
}

resource "aws_cloudfront_distribution" "distribution" {
  origin {
    domain_name = aws_s3_bucket.bucket.bucket_regional_domain_name
    origin_id   = var.origin_id

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.oai.cloudfront_access_identity_path
    }
  }

  aliases             = var.aliases
  default_root_object = var.default_root_object
  enabled             = var.enabled
  is_ipv6_enabled     = var.is_ipv6_enabled
  comment             = var.distribution_comment

  default_cache_behavior {
    allowed_methods  = var.default_cache_behavior_allowed_methods
    cached_methods   = var.default_cache_behavior_cached_methods
    target_origin_id = var.default_cache_behavior_target_origin_id

    forwarded_values {
      query_string = var.default_cache_behavior_forwarder_query_string

      cookies {
        forward = var.default_cache_behavior_forwarder_cookies
      }
    }

    viewer_protocol_policy = var.viewer_protocol_policy
    min_ttl                = var.min_ttl
    default_ttl            = var.default_ttl
    max_ttl                = var.max_ttl
    compress               = var.compress
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