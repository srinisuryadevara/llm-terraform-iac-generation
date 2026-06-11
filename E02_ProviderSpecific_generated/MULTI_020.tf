# Configure the AWS Provider
provider "aws" {
  region = var.aws_region
}

# Configure the Azure Provider
provider "azurerm" {
  features {}
  subscription_id = var.azure_subscription_id
  client_id       = var.azure_client_id
  client_secret   = var.azure_client_secret
  tenant_id       = var.azure_tenant_id
}

# Configure the GCP Provider
provider "google" {
  project = var.gcp_project
  region  = var.gcp_region
}

# Create an AWS CloudFront distribution
resource "aws_cloudfront_distribution" "aws_cdn" {
  origin {
    domain_name = var.aws_origin_domain_name
    origin_id   = var.aws_origin_id
  }

  enabled = true

  default_root_object = var.aws_default_root_object

  aliases = var.aws_aliases

  default_cache_behavior {
    allowed_methods  = var.aws_allowed_methods
    cached_methods   = var.aws_cached_methods
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
    acm_certificate_arn = var.aws_acm_certificate_arn
    ssl_support_method  = "sni-only"
  }
}

# Create an Azure CDN profile and endpoint
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
    name      = var.azure_origin_name
    host_name = var.azure_origin_host_name
  }
}

# Create a GCP Cloud CDN backend service and URL map
resource "google_compute_backend_service" "gcp_cdn" {
  name        = var.gcp_backend_service_name
  port_name   = var.gcp_port_name
  protocol    = var.gcp_protocol
  timeout_sec = var.gcp_timeout_sec

  backend {
    group = var.gcp_backend_group
  }

  health_checks = [var.gcp_health_check]
}

resource "google_compute_url_map" "gcp_cdn_url_map" {
  name            = var.gcp_url_map_name
  default_service = google_compute_backend_service.gcp_cdn.self_link

  host_rule {
    hosts        = var.gcp_hosts
    service      = google_compute_backend_service.gcp_cdn.self_link
  }

  path_matcher {
    name            = var.gcp_path_matcher_name
    default_service = google_compute_backend_service.gcp_cdn.self_link

    path_rule {
      paths   = var.gcp_paths
      service = google_compute_backend_service.gcp_cdn.self_link
    }
  }
}

resource "google_compute_target_http_proxy" "gcp_cdn_proxy" {
  name    = var.gcp_proxy_name
  url_map = google_compute_url_map.gcp_cdn_url_map.self_link
}

resource "google_compute_target_https_proxy" "gcp_cdn_https_proxy" {
  name             = var.gcp_https_proxy_name
  url_map           = google_compute_url_map.gcp_cdn_url_map.self_link
  ssl_certificates = [var.gcp_ssl_certificate]
}

resource "google_compute_global_forwarding_rule" "gcp_cdn_forwarding_rule" {
  name       = var.gcp_forwarding_rule_name
  target     = google_compute_target_http_proxy.gcp_cdn_proxy.self_link
  port_range = var.gcp_port_range
}

resource "google_compute_global_forwarding_rule" "gcp_cdn_https_forwarding_rule" {
  name       = var.gcp_https_forwarding_rule_name
  target     = google_compute_target_https_proxy.gcp_cdn_https_proxy.self_link
  port_range = var.gcp_https_port_range
}