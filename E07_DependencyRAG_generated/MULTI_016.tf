# Configure the AWS Provider
provider "aws" {
  region = var.aws_region
}

# Configure the Azure Provider
provider "azurerm" {
  features {}
}

# Configure the Google Cloud Provider
provider "google" {
  project = var.gcp_project
  region  = var.gcp_region
}

# Configure the Google Cloud Beta Provider
provider "google-beta" {
  project = var.gcp_project
  region  = var.gcp_region
}

# Create an AWS S3 Bucket
resource "aws_s3_bucket" "aws_bucket" {
  bucket = var.aws_bucket_name
  acl    = "private"
}

# Create an Azure Storage Account
resource "azurerm_storage_account" "azure_storage" {
  name                     = var.azure_storage_account_name
  resource_group_name      = var.azure_resource_group_name
  location                 = var.azure_location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# Create a Google Cloud Storage Bucket
resource "google_storage_bucket" "gcp_bucket" {
  name     = var.gcp_bucket_name
  location = var.gcp_location
  storage_class = "Standard"
}

# Create an AWS CloudFront Distribution
resource "aws_cloudfront_distribution" "aws_cdn" {
  origin {
    domain_name = aws_s3_bucket.aws_bucket.bucket_regional_domain_name
    origin_id   = "aws-s3-bucket"
  }

  enabled = true

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "aws-s3-bucket"

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

# Create an Azure CDN Profile
resource "azurerm_cdn_profile" "azure_cdn_profile" {
  name                = var.azure_cdn_profile_name
  resource_group_name = var.azure_resource_group_name
  sku                 = "Standard_Microsoft"
  location            = var.azure_location
}

# Create an Azure CDN Endpoint
resource "azurerm_cdn_endpoint" "azure_cdn_endpoint" {
  name                = var.azure_cdn_endpoint_name
  profile_name        = azurerm_cdn_profile.azure_cdn_profile.name
  resource_group_name = var.azure_resource_group_name
  location            = var.azure_location

  origin {
    name      = "azure-storage"
    host_name = azurerm_storage_account.azure_storage.primary_blob_host
  }
}

# Create a Google Cloud CDN
resource "google_compute_backend_bucket" "gcp_cdn_backend" {
  name        = var.gcp_cdn_backend_name
  bucket_name = google_storage_bucket.gcp_bucket.name
}

resource "google_compute_url_map" "gcp_cdn_url_map" {
  name            = var.gcp_cdn_url_map_name
  default_service = google_compute_backend_bucket.gcp_cdn_backend.self_link

  host_rule {
    hosts        = ["*"]
    service      = google_compute_backend_bucket.gcp_cdn_backend.self_link
  }

  path_matcher {
    name            = "allpaths"
    default_service = google_compute_backend_bucket.gcp_cdn_backend.self_link

    path_rule {
      paths   = ["/*"]
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
  port_range = "80"
}