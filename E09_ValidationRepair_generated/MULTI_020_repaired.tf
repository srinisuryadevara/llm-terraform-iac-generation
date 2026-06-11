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

# Create an AWS CloudFront Distribution
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

  tags = {
    Environment = "production"
    Project     = "cdn-setup"
  }
}

# Create an Azure CDN Profile and Endpoint
resource "azurerm_cdn_profile" "azure_cdn" {
  name                = var.azure_cdn_profile_name
  resource_group_name = var.azure_resource_group_name
  sku                 = "Standard_Microsoft"
  location            = var.azure_location

  tags = {
    Environment = "production"
    Project     = "cdn-setup"
  }
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

  tags = {
    Environment = "production"
    Project     = "cdn-setup"
  }
}

# Create a GCP Cloud CDN Enabled Backend Bucket
resource "google_storage_bucket" "gcp_cdn_bucket" {
  name     = var.gcp_bucket_name
  location = var.gcp_location
  storage_class = "REGIONAL"

  labels = {
    Environment = "production"
    Project     = "cdn-setup"
  }
}

resource "google_compute_backend_bucket" "gcp_cdn_backend" {
  name        = var.gcp_backend_name
  bucket_name = google_storage_bucket.gcp_cdn_bucket.name
  enable_cdn  = true

  labels = {
    Environment = "production"
    Project     = "cdn-setup"
  }
}

resource "google_compute_url_map" "gcp_cdn_url_map" {
  name            = var.gcp_url_map_name
  default_service = google_compute_backend_bucket.gcp_cdn_backend.self_link

  labels = {
    Environment = "production"
    Project     = "cdn-setup"
  }
}

resource "google_compute_target_http_proxy" "gcp_cdn_proxy" {
  name    = var.gcp_proxy_name
  url_map = google_compute_url_map.gcp_cdn_url_map.self_link

  labels = {
    Environment = "production"
    Project     = "cdn-setup"
  }
}

resource "google_compute_global_forwarding_rule" "gcp_cdn_forwarding_rule" {
  name       = var.gcp_forwarding_rule_name
  target     = google_compute_target_http_proxy.gcp_cdn_proxy.self_link
  port_range = "80"

  labels = {
    Environment = "production"
    Project     = "cdn-setup"
  }
}

variable "aws_region" {
  type = string
}

variable "aws_origin_domain_name" {
  type = string
}

variable "aws_origin_id" {
  type = string
}

variable "azure_subscription_id" {
  type = string
}

variable "azure_client_id" {
  type = string
}

variable "azure_client_secret" {
  type = string
}

variable "azure_tenant_id" {
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

variable "azure_cdn_endpoint_name" {
  type = string
}

variable "azure_origin_name" {
  type = string
}

variable "azure_origin_host_name" {
  type = string
}

variable "gcp_project" {
  type = string
}

variable "gcp_region" {
  type = string
}

variable "gcp_bucket_name" {
  type = string
}

variable "gcp_location" {
  type = string
}

variable "gcp_backend_name" {
  type = string
}

variable "gcp_url_map_name" {
  type = string
}

variable "gcp_proxy_name" {
  type = string
}

variable "gcp_forwarding_rule_name" {
  type = string
}

output "aws_cdn_distribution_id" {
  value = aws_cloudfront_distribution.aws_cdn.id
}

output "aws_cdn_distribution_arn" {
  value = aws_cloudfront_distribution.aws_cdn.arn
}

output "azure_cdn_profile_id" {
  value = azurerm_cdn_profile.azure_cdn.id
}

output "azure_cdn_endpoint_id" {
  value = azurerm_cdn_endpoint.azure_cdn_endpoint.id
}

output "gcp_cdn_bucket_name" {
  value = google_storage_bucket.gcp_cdn_bucket.name
}

output "gcp_cdn_backend_bucket_name" {
  value = google_compute_backend_bucket.gcp_cdn_backend.bucket_name
}

output "gcp_cdn_url_map_name" {
  value = google_compute_url_map.gcp_cdn_url_map.name
}

output "gcp_cdn_proxy_name" {
  value = google_compute_target_http_proxy.gcp_cdn_proxy.name
}

output "gcp_cdn_forwarding_rule_name" {
  value = google_compute_global_forwarding_rule.gcp_cdn_forwarding_rule.name
}