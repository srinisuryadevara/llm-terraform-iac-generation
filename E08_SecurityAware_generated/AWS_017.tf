provider "aws" {
  region = var.region
}

variable "region" {
  type        = string
  description = "AWS Region"
}

variable "project" {
  type        = string
  description = "Project Name"
}

variable "environment" {
  type        = string
  description = "Environment"
}

variable "bucket_name" {
  type        = string
  description = "S3 Bucket Name"
}

variable "oai_comment" {
  type        = string
  description = "OAI Comment"
}

variable "tls_min_version" {
  type        = string
  default     = "TLSv1.2"
}

variable "allowed_cidr_blocks" {
  type        = list(string)
  description = "Allowed CIDR Blocks for S3 Bucket Policy"
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
    Environment = var.environment
    Project     = var.project
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
      {
        Sid       = "DenyUnencryptedTraffic"
        Effect    = "Deny"
        Principal = "*"
        Action   = "s3:*"
        Resource = "${aws_s3_bucket.this.arn}/*"
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      },
      {
        Sid       = "DenyNonTLSRequests"
        Effect    = "Deny"
        Principal = "*"
        Action   = "s3:*"
        Resource = "${aws_s3_bucket.this.arn}/*"
        Condition = {
          StringNotEquals = {
            "aws:Protocol" = "https"
          }
        }
      },
    ]
  })
}

resource "aws_cloudfront_distribution" "this" {
  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"
  aliases             = [var.bucket_name]

  origin {
    domain_name = aws_s3_bucket.this.bucket_regional_domain_name
    origin_id   = "S3Origin"

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.this.cloudfront_access_identity_path
    }
  }

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3Origin"

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
    acm_certificate_arn = aws_acm_certificate.this.arn
    ssl_support_method  = "sni-only"
    minimum_protocol_version = var.tls_min_version
  }

  tags = {
    Name        = var.bucket_name
    Environment = var.environment
    Project     = var.project
  }
}

resource "aws_cloudfront_origin_access_identity" "this" {
  comment = var.oai_comment
}

resource "aws_acm_certificate" "this" {
  domain_name       = var.bucket_name
  validation_method = "DNS"

  tags = {
    Name        = var.bucket_name
    Environment = var.environment
    Project     = var.project
  }
}

resource "aws_acm_certificate_validation" "this" {
  certificate_arn = aws_acm_certificate.this.arn
  validation_record {
    name    = aws_acm_certificate.this.domain_validation_options[0].resource_record_name
    type    = aws_acm_certificate.this.domain_validation_options[0].resource_record_type
    value   = aws_acm_certificate.this.domain_validation_options[0].resource_record_value
  }
}