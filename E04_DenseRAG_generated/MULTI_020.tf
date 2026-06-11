# AWS CloudFront CDN Setup
provider "aws" {
  region = var.aws_region
}

resource "aws_cloudfront_distribution" "aws_cdn" {
  origin {
    domain_name = var.aws_origin_domain
    origin_id   = var.aws_origin_id
  }

  enabled = true

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = var.aws_origin_id

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
    cloudfront_default_certificate = true
  }
}

# Azure CDN Setup
provider "azurerm" {
  version = "2.34.0"
  features {}
}

resource "azurerm_cdn_profile" "azure_cdn" {
  name                = var.azure_cdn_profile_name
  resource_group_name = var.azure_resource_group_name
  location            = var.azure_location
  sku                 = var.azure_cdn_sku
}

resource "azurerm_cdn_endpoint" "azure_cdn_endpoint" {
  name                = var.azure_cdn_endpoint_name
  profile_name        = azurerm_cdn_profile.azure_cdn.name
  location            = var.azure_location
  resource_group_name = var.azure_resource_group_name

  origin {
    name       = var.azure_origin_name
    host_name  = var.azure_origin_host_name
    http_port  = var.azure_origin_http_port
    https_port = var.azure_origin_https_port
  }
}

# GCP Cloud CDN Setup
provider "google" {
  project = var.gcp_project
  region  = var.gcp_region
}

resource "google_compute_backend_bucket" "gcp_cdn_backend" {
  name        = var.gcp_cdn_backend_name
  bucket_name = var.gcp_cdn_backend_bucket_name
}

resource "google_compute_url_map" "gcp_cdn_url_map" {
  name            = var.gcp_cdn_url_map_name
  default_service = google_compute_backend_bucket.gcp_cdn_backend.self_link

  host_rule {
    hosts        = [var.gcp_cdn_host]
    service      = google_compute_backend_bucket.gcp_cdn_backend.self_link
  }

  path_matcher {
    name            = var.gcp_cdn_path_matcher_name
    default_service = google_compute_backend_bucket.gcp_cdn_backend.self_link

    path_rule {
      paths   = [var.gcp_cdn_path]
      service = google_compute_backend_bucket.gcp_cdn_backend.self_link
    }
  }
}

resource "google_compute_target_http_proxy" "gcp_cdn_target_http_proxy" {
  name    = var.gcp_cdn_target_http_proxy_name
  url_map = google_compute_url_map.gcp_cdn_url_map.self_link
}

resource "google_compute_global_forwarding_rule" "gcp_cdn_global_forwarding_rule" {
  name       = var.gcp_cdn_global_forwarding_rule_name
  target     = google_compute_target_http_proxy.gcp_cdn_target_http_proxy.self_link
  port_range = var.gcp_cdn_port_range
}

variable "aws_region" {
  type = string
}

variable "aws_origin_domain" {
  type = string
}

variable "aws_origin_id" {
  type = string
}

variable "azure_cdn_profile_name" {
  type = string
}

variable "azure_resource_group_name" {
  type = string
}

variable "azure_location" {
  type = string
}

variable "azure_cdn_sku" {
  type = string
}

variable "azure_cdn_endpoint_name" {
  type = string
}

variable "azure_origin_name" {
  type = string
}

variable "azure_origin_host_name" {
  type = string
}

variable "azure_origin_http_port" {
  type = number
}

variable "azure_origin_https_port" {
  type = number
}

variable "gcp_project" {
  type = string
}

variable "gcp_region" {
  type = string
}

variable "gcp_cdn_backend_name" {
  type = string
}

variable "gcp_cdn_backend_bucket_name" {
  type = string
}

variable "gcp_cdn_url_map_name" {
  type = string
}

variable "gcp_cdn_host" {
  type = string
}

variable "gcp_cdn_path_matcher_name" {
  type = string
}

variable "gcp_cdn_path" {
  type = string
}

variable "gcp_cdn_target_http_proxy_name" {
  type = string
}

variable "gcp_cdn_global_forwarding_rule_name" {
  type = string
}

variable "gcp_cdn_port_range" {
  type = string
}