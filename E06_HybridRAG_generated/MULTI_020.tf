# AWS CloudFront
resource "aws_cloudfront_origin_access_identity" "app_bucket_dist_oai" {
  comment  = "access-identity-react-cors-spa-${aws_api_gateway_rest_api.app_rest_api.id}"
}

data "aws_iam_policy_document" "app_bucket_policy" {
  statement {
    sid       = "PolicyForCloudFrontPrivateContent"
    actions   = ["s3:GetObject"]
    resources = ["${module.app_bucket.bucket.arn}/*"]

    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.app_bucket_dist_oai.iam_arn]
    }
  }
}

resource "aws_s3_bucket_policy" "app_bucket_policy" {
  bucket = module.app_bucket.bucket.id
  policy = data.aws_iam_policy_document.app_bucket_policy.json
}

locals {
  app_bucket_origin_id = module.app_bucket.bucket.bucket_regional_domain_name
}

data "aws_cloudfront_cache_policy" "managed_caching_optimized" {
  name = "Managed-CachingOptimized"
}

data "aws_cloudfront_origin_request_policy" "managed_cors_s3origin" {
  name = "Managed-CORS-S3Origin"
}

resource "aws_cloudfront_distribution" "app_bucket_dist" {
  origin {
    origin_id   = local.app_bucket_origin_id
    domain_name = module.app_bucket.bucket.bucket_regional_domain_name
    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.app_bucket_dist_oai.cloudfront_access_identity_path
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"
  http_version        = "http2"
}

# Azure CDN
resource "azurerm_cdn_profile" "example" {
  name                = var.cdn_profile_name
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = var.cdn_sku
}

resource "azurerm_cdn_endpoint" "example" {
  name                = var.cdn_endpoint_name
  profile_name        = azurerm_cdn_profile.example.name
  resource_group_name = var.resource_group_name
  location            = var.location

  origin {
    name      = var.origin_name
    host_name = var.origin_host_name
  }
}

# GCP Cloud CDN
resource "google_compute_backend_bucket" "example" {
  name        = var.backend_bucket_name
  bucket_name = var.bucket_name
  enable_cdn  = true
}

resource "google_compute_url_map" "example" {
  name            = var.url_map_name
  default_service = google_compute_backend_bucket.example.self_link
}

resource "google_compute_target_http_proxy" "example" {
  name    = var.target_http_proxy_name
  url_map = google_compute_url_map.example.self_link
}

resource "google_compute_global_forwarding_rule" "example" {
  name       = var.global_forwarding_rule_name
  target     = google_compute_target_http_proxy.example.self_link
  port_range = var.port_range
}