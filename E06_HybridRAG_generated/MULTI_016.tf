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
  default_service = google_compute_backend_service.example.self_link

  host_rule {
    hosts        = [var.host]
    service      = google_compute_backend_service.example.self_link
  }

  path_matcher {
    name            = var.path_matcher_name
    default_service = google_compute_backend_service.example.self_link

    path_rule {
      paths   = [var.path]
      service = google_compute_backend_service.example.self_link
    }
  }
}

resource "google_compute_backend_service" "example" {
  name        = var.backend_service_name
  port_name   = var.port_name
  protocol    = var.protocol
  timeout_sec = var.timeout_sec

  backend {
    group = google_compute_instance_group.example.self_link
  }

  health_checks = [google_compute_health_check.example.self_link]
}

resource "google_compute_instance_group" "example" {
  name        = var.instance_group_name
  zone        = var.zone
  instances   = [google_compute_instance.example.self_link]
  named_port {
    name = var.named_port_name
    port = var.named_port
  }
}

resource "google_compute_instance" "example" {
  name         = var.instance_name
  machine_type = var.machine_type
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = var.image
    }
  }

  network_interface {
    network = var.network
  }
}

resource "google_compute_health_check" "example" {
  name                = var.health_check_name
  check_interval_sec  = var.check_interval_sec
  timeout_sec         = var.timeout_sec
  healthy_threshold   = var.healthy_threshold
  unhealthy_threshold = var.unhealthy_threshold

  http_health_check {
    port = var.port
  }
}

variable "project_id" {
  type = string
}

variable "cdn_profile_name" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "cdn_sku" {
  type = string
}

variable "cdn_endpoint_name" {
  type = string
}

variable "origin_name" {
  type = string
}

variable "origin_host_name" {
  type = string
}

variable "backend_bucket_name" {
  type = string
}

variable "bucket_name" {
  type = string
}

variable "url_map_name" {
  type = string
}

variable "host" {
  type = string
}

variable "path_matcher_name" {
  type = string
}

variable "path" {
  type = string
}

variable "backend_service_name" {
  type = string
}

variable "port_name" {
  type = string
}

variable "protocol" {
  type = string
}

variable "timeout_sec" {
  type = number
}

variable "instance_group_name" {
  type = string
}

variable "zone" {
  type = string
}

variable "instance_name" {
  type = string
}

variable "machine_type" {
  type = string
}

variable "image" {
  type = string
}

variable "network" {
  type = string
}

variable "named_port_name" {
  type = string
}

variable "named_port" {
  type = number
}

variable "health_check_name" {
  type = string
}

variable "check_interval_sec" {
  type = number
}

variable "healthy_threshold" {
  type = number
}

variable "unhealthy_threshold" {
  type = number
}

variable "port" {
  type = number
}