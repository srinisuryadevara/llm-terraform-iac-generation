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

# Configure the Google Cloud Provider
provider "google" {
  project = var.gcp_project
  region  = var.gcp_region
}

# AWS CloudFront Distribution
resource "aws_cloudfront_distribution" "aws_cdn" {
  origin {
    domain_name = var.aws_origin_domain_name
    origin_id   = var.aws_origin_id
  }

  enabled             = true
  is_ipv6_enabled     = true
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

  tags = {
    Environment = var.environment
    Project     = var.project
  }
}

# Azure CDN Profile and Endpoint
resource "azurerm_cdn_profile" "azure_cdn" {
  name                = var.azure_cdn_profile_name
  resource_group_name = var.azure_resource_group_name
  location            = var.azure_location
  sku                 = var.azure_cdn_sku

  tags = {
    Environment = var.environment
    Project     = var.project
  }
}

resource "azurerm_cdn_endpoint" "azure_cdn" {
  name                = var.azure_cdn_endpoint_name
  profile_name        = azurerm_cdn_profile.azure_cdn.name
  resource_group_name = var.azure_resource_group_name
  location            = var.azure_location

  origin {
    name      = var.azure_origin_name
    host_name = var.azure_origin_host_name
  }

  tags = {
    Environment = var.environment
    Project     = var.project
  }
}

# GCP Cloud CDN
resource "google_compute_backend_bucket" "gcp_cdn" {
  name        = var.gcp_backend_bucket_name
  bucket_name = var.gcp_bucket_name
  enable_cdn  = true
}

resource "google_compute_url_map" "gcp_cdn" {
  name            = var.gcp_url_map_name
  default_service = google_compute_backend_bucket.gcp_cdn.self_link

  host_rule {
    hosts        = var.gcp_hosts
    service      = google_compute_backend_bucket.gcp_cdn.self_link
  }

  path_matcher {
    name            = var.gcp_path_matcher_name
    default_service = google_compute_backend_bucket.gcp_cdn.self_link

    path_rule {
      paths   = var.gcp_paths
      service = google_compute_backend_bucket.gcp_cdn.self_link
    }
  }

  tags = {
    Environment = var.environment
    Project     = var.project
  }
}

resource "google_compute_target_https_proxy" "gcp_cdn" {
  name             = var.gcp_target_https_proxy_name
  url_map          = google_compute_url_map.gcp_cdn.self_link
  ssl_certificates = [var.gcp_ssl_certificate]
}

resource "google_compute_global_forwarding_rule" "gcp_cdn" {
  name       = var.gcp_global_forwarding_rule_name
  target     = google_compute_target_https_proxy.gcp_cdn.self_link
  port_range = var.gcp_port_range

  tags = {
    Environment = var.environment
    Project     = var.project
  }
}

variable "aws_region" {
  type        = string
  description = "AWS Region"
}

variable "aws_origin_domain_name" {
  type        = string
  description = "AWS Origin Domain Name"
}

variable "aws_origin_id" {
  type        = string
  description = "AWS Origin ID"
}

variable "aws_default_root_object" {
  type        = string
  description = "AWS Default Root Object"
}

variable "aws_aliases" {
  type        = list(string)
  description = "AWS Aliases"
}

variable "aws_allowed_methods" {
  type        = list(string)
  description = "AWS Allowed Methods"
}

variable "aws_cached_methods" {
  type        = list(string)
  description = "AWS Cached Methods"
}

variable "aws_acm_certificate_arn" {
  type        = string
  description = "AWS ACM Certificate ARN"
}

variable "azure_subscription_id" {
  type        = string
  description = "Azure Subscription ID"
}

variable "azure_client_id" {
  type        = string
  description = "Azure Client ID"
}

variable "azure_client_secret" {
  type        = string
  description = "Azure Client Secret"
}

variable "azure_tenant_id" {
  type        = string
  description = "Azure Tenant ID"
}

variable "azure_cdn_profile_name" {
  type        = string
  description = "Azure CDN Profile Name"
}

variable "azure_resource_group_name" {
  type        = string
  description = "Azure Resource Group Name"
}

variable "azure_location" {
  type        = string
  description = "Azure Location"
}

variable "azure_cdn_sku" {
  type        = string
  description = "Azure CDN SKU"
}

variable "azure_cdn_endpoint_name" {
  type        = string
  description = "Azure CDN Endpoint Name"
}

variable "azure_origin_name" {
  type        = string
  description = "Azure Origin Name"
}

variable "azure_origin_host_name" {
  type        = string
  description = "Azure Origin Host Name"
}

variable "gcp_project" {
  type        = string
  description = "GCP Project"
}

variable "gcp_region" {
  type        = string
  description = "GCP Region"
}

variable "gcp_backend_bucket_name" {
  type        = string
  description = "GCP Backend Bucket Name"
}

variable "gcp_bucket_name" {
  type        = string
  description = "GCP Bucket Name"
}

variable "gcp_url_map_name" {
  type        = string
  description = "GCP URL Map Name"
}

variable "gcp_hosts" {
  type        = list(string)
  description = "GCP Hosts"
}

variable "gcp_path_matcher_name" {
  type        = string
  description = "GCP Path Matcher Name"
}

variable "gcp_paths" {
  type        = list(string)
  description = "GCP Paths"
}

variable "gcp_target_https_proxy_name" {
  type        = string
  description = "GCP Target HTTPS Proxy Name"
}

variable "gcp_ssl_certificate" {
  type        = string
  description = "GCP SSL Certificate"
}

variable "gcp_global_forwarding_rule_name" {
  type        = string
  description = "GCP Global Forwarding Rule Name"
}

variable "gcp_port_range" {
  type        = string
  description = "GCP Port Range"
}

variable "environment" {
  type        = string
  description = "Environment"
}

variable "project" {
  type        = string
  description = "Project"
}