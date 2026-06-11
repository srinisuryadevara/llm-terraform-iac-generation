# Configure the AWS Provider
provider "aws" {
  region = var.aws_region
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}

# Configure the Azure Provider
provider "azurerm" {
  features {}
  subscription_id = var.azure_subscription_id
  client_id      = var.azure_client_id
  client_secret = var.azure_client_secret
  tenant_id      = var.azure_tenant_id
}

# Configure the Google Cloud Provider
provider "google" {
  project = var.gcp_project
  region  = var.gcp_region
  credentials = var.gcp_credentials
}

# Create an AWS CloudFront Distribution
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
    target_origin_id = var.aws_target_origin_id

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

  tags = {
    Environment = "production"
    Project     = "cdn-setup"
  }
}

# Create an Azure CDN Profile and Endpoint
resource "azurerm_cdn_profile" "azure_cdn" {
  name                = var.azure_cdn_profile_name
  resource_group_name = var.azure_resource_group_name
  location            = var.azure_location
  sku                 = var.azure_cdn_sku

  tags = {
    Environment = "production"
    Project     = "cdn-setup"
  }
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

  tags = {
    Environment = "production"
    Project     = "cdn-setup"
  }
}

# Create a GCP Cloud CDN Enabled Backend Bucket
resource "google_storage_bucket" "gcp_bucket" {
  name     = var.gcp_bucket_name
  location = var.gcp_location
  force_destroy = true

  labels = {
    Environment = "production"
    Project     = "cdn-setup"
  }
}

resource "google_compute_backend_bucket" "gcp_backend_bucket" {
  name        = var.gcp_backend_bucket_name
  bucket_name = google_storage_bucket.gcp_bucket.name
  enable_cdn  = true

  labels = {
    Environment = "production"
    Project     = "cdn-setup"
  }
}

resource "google_compute_url_map" "gcp_url_map" {
  name            = var.gcp_url_map_name
  default_service = google_compute_backend_bucket.gcp_backend_bucket.self_link

  host_rule {
    hosts        = var.gcp_hosts
    service      = google_compute_backend_bucket.gcp_backend_bucket.self_link
  }

  path_matcher {
    name            = var.gcp_path_matcher_name
    default_service = google_compute_backend_bucket.gcp_backend_bucket.self_link

    path_rule {
      paths   = var.gcp_paths
      service = google_compute_backend_bucket.gcp_backend_bucket.self_link
    }
  }

  labels = {
    Environment = "production"
    Project     = "cdn-setup"
  }
}

resource "google_compute_target_http_proxy" "gcp_target_http_proxy" {
  name    = var.gcp_target_http_proxy_name
  url_map = google_compute_url_map.gcp_url_map.self_link

  labels = {
    Environment = "production"
    Project     = "cdn-setup"
  }
}

resource "google_compute_global_forwarding_rule" "gcp_global_forwarding_rule" {
  name       = var.gcp_global_forwarding_rule_name
  target     = google_compute_target_http_proxy.gcp_target_http_proxy.self_link
  port_range = var.gcp_port_range

  labels = {
    Environment = "production"
    Project     = "cdn-setup"
  }
}

# Output blocks for key resource attributes
output "aws_cloudfront_distribution_id" {
  value = aws_cloudfront_distribution.aws_cdn.id
}

output "aws_cloudfront_distribution_arn" {
  value = aws_cloudfront_distribution.aws_cdn.arn
}

output "azure_cdn_profile_id" {
  value = azurerm_cdn_profile.azure_cdn.id
}

output "azure_cdn_endpoint_id" {
  value = azurerm_cdn_endpoint.azure_cdn_endpoint.id
}

output "gcp_backend_bucket_name" {
  value = google_compute_backend_bucket.gcp_backend_bucket.name
}

output "gcp_url_map_name" {
  value = google_compute_url_map.gcp_url_map.name
}

output "gcp_target_http_proxy_name" {
  value = google_compute_target_http_proxy.gcp_target_http_proxy.name
}

output "gcp_global_forwarding_rule_name" {
  value = google_compute_global_forwarding_rule.gcp_global_forwarding_rule.name
}