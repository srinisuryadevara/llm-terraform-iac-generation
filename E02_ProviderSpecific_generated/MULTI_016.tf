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

# Create AWS CloudFront Distribution
resource "aws_cloudfront_distribution" "aws_cdn" {
  origin {
    domain_name = var.aws_origin_domain_name
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

# Create Azure CDN Profile and Endpoint
resource "azurerm_cdn_profile" "azure_cdn" {
  name                = var.azure_cdn_profile_name
  resource_group_name = var.azure_resource_group_name
  sku                 = "Standard_Microsoft"
  location            = var.azure_location
}

resource "azurerm_cdn_endpoint" "azure_cdn_endpoint" {
  name                = var.azure_cdn_endpoint_name
  profile_name        = azurerm_cdn_profile.azure_cdn.name
  resource_group_name = var.azure_resource_group_name
  location            = var.azure_location

  origin {
    name      = var.azure_origin_name
    host_name = var.azure_origin_host_name
  }
}

# Create GCP Cloud CDN
resource "google_compute_backend_bucket" "gcp_cdn" {
  name        = var.gcp_backend_bucket_name
  bucket_name = var.gcp_bucket_name
}

resource "google_compute_url_map" "gcp_cdn_url_map" {
  name            = var.gcp_url_map_name
  default_service = google_compute_backend_bucket.gcp_cdn.self_link

  host_rule {
    hosts        = [var.gcp_host]
    service      = google_compute_backend_bucket.gcp_cdn.self_link
  }

  path_matcher {
    name            = var.gcp_path_matcher_name
    default_service = google_compute_backend_bucket.gcp_cdn.self_link

    path_rule {
      paths   = [var.gcp_path]
      service = google_compute_backend_bucket.gcp_cdn.self_link
    }
  }
}

resource "google_compute_target_http_proxy" "gcp_cdn_proxy" {
  name    = var.gcp_target_http_proxy_name
  url_map = google_compute_url_map.gcp_cdn_url_map.self_link
}

resource "google_compute_global_forwarding_rule" "gcp_cdn_forwarding_rule" {
  name       = var.gcp_global_forwarding_rule_name
  target     = google_compute_target_http_proxy.gcp_cdn_proxy.self_link
  port_range = var.gcp_port_range
}