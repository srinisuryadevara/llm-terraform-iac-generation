# Configure the AWS provider
provider "aws" {
  region = var.aws_region
}

# Configure the Azure provider
provider "azurerm" {
  features {}
}

# Configure the Google Cloud provider
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

# Create an Azure CDN profile
resource "azurerm_cdn_profile" "azure_cdn" {
  name                = var.azure_cdn_profile_name
  resource_group_name = var.azure_resource_group_name
  sku                 = "Standard_Microsoft"
  location            = var.azure_location
}

# Create an Azure CDN endpoint
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

# Create a GCP Cloud Storage bucket
resource "google_storage_bucket" "gcp_bucket" {
  name     = var.gcp_bucket_name
  location = var.gcp_location
}

# Create a GCP Cloud CDN backend bucket
resource "google_compute_backend_bucket" "gcp_backend_bucket" {
  name        = var.gcp_backend_bucket_name
  bucket_name = google_storage_bucket.gcp_bucket.name
  enable_cdn  = true
}

# Create a GCP Cloud CDN URL map
resource "google_compute_url_map" "gcp_url_map" {
  name            = var.gcp_url_map_name
  default_service = google_compute_backend_bucket.gcp_backend_bucket.self_link
}

# Create a GCP Cloud CDN target HTTP proxy
resource "google_compute_target_http_proxy" "gcp_target_http_proxy" {
  name    = var.gcp_target_http_proxy_name
  url_map = google_compute_url_map.gcp_url_map.self_link
}

# Create a GCP Cloud CDN forwarding rule
resource "google_compute_global_forwarding_rule" "gcp_forwarding_rule" {
  name       = var.gcp_forwarding_rule_name
  target     = google_compute_target_http_proxy.gcp_target_http_proxy.self_link
  port_range = "80"
}