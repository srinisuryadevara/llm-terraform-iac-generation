# AWS CloudFront
provider "aws" {
  alias  = "cloudfront"
  region = "us-east-1"
}

variable "aws_domain" {
  type = string
}

resource "aws_cloudfront_origin_access_identity" "aws_static_site" {
  comment = var.aws_domain
}

data "aws_iam_policy_document" "aws_read_static_site_bucket" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.aws_static_site.arn}/*"]

    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.aws_static_site.iam_arn]
    }
  }

  statement {
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.aws_static_site.arn]

    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.aws_static_site.iam_arn]
    }
  }
}

resource "aws_s3_bucket" "aws_static_site" {
  bucket = var.aws_domain
}

resource "aws_s3_bucket_acl" "aws_static_site" {
  bucket = aws_s3_bucket.aws_static_site.id
  acl    = "private"
}

resource "aws_s3_bucket_policy" "aws_static_site" {
  bucket = aws_s3_bucket.aws_static_site.id
  policy = data.aws_iam_policy_document.aws_read_static_site_bucket.json
}

resource "aws_cloudfront_distribution" "aws_static_site" {
  origin {
    origin_id   = aws_s3_bucket.aws_static_site.id
    domain_name = aws_s3_bucket.aws_static_site.bucket_regional_domain_name
    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.aws_static_site.cloudfront_access_identity_path
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"
  http_version        = "http2"
}

# Azure CDN
provider "azurerm" {
  alias = "cdn"
  features {}
}

variable "azure_domain" {
  type = string
}

resource "azurerm_resource_group" "azure_cdn" {
  name     = "azure-cdn"
  location = "canadaeast"
}

resource "azurerm_cdn_profile" "azure_cdn" {
  name                = "azure-cdn"
  resource_group_name = azurerm_resource_group.azure_cdn.name
  location            = "canadaeast"
  sku                 = "Standard_Microsoft"
}

resource "azurerm_storage_account" "azure_cdn" {
  name                     = var.azure_domain
  resource_group_name      = azurerm_resource_group.azure_cdn.name
  location                 = "canadaeast"
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

locals {
  azure_host_name = regex("^https://(.*)/$", azurerm_storage_account.azure_cdn.primary_web_endpoint)[0]
}

resource "azurerm_cdn_endpoint" "azure_cdn" {
  name                = "azure-cdn"
  profile_name        = azurerm_cdn_profile.azure_cdn.name
  resource_group_name = azurerm_resource_group.azure_cdn.name
  location            = "canadaeast"
  origin {
    name      = "origin1"
    host_name = local.azure_host_name
  }
  origin_host_header = local.azure_host_name

  delivery_rule {
    name  = "httpsredirect"
    order = 1

    request_scheme_condition {
      match_values = [
        "HTTP",
      ]
      negate_condition = false
      operator         = "Equal"
    }

    url_redirect_action {
      protocol      = "Https"
      redirect_type = "PermanentRedirect"
    }
  }

  lifecycle {
    ignore_changes = [origin, is_compression_enabled]
  }
}

resource "azurerm_cdn_endpoint_custom_domain" "azure_cdn" {
  cdn_endpoint_id = azurerm_cdn_endpoint.azure_cdn.id
  name            = "azure-cdn"
  host_name       = var.azure_domain
  user_managed_https {
    key_vault_certificate_id = "https://azure-cdn.vault.azure.net/certificates/azure-cdn"
  }
}

# GCP Cloud CDN
provider "google" {
  alias = "cloudcdn"
  project = var.gcp_project
  region  = "us-central1"
}

variable "gcp_project" {
  type = string
}

variable "gcp_domain" {
  type = string
}

resource "google_compute_backend_bucket" "gcp_cdn" {
  name        = var.gcp_domain
  bucket_name = var.gcp_domain
  enable_cdn  = true
}

resource "google_compute_url_map" "gcp_cdn" {
  name            = var.gcp_domain
  default_service = google_compute_backend_bucket.gcp_cdn.self_link

  host_rule {
    hosts        = [var.gcp_domain]
    service      = google_compute_backend_bucket.gcp_cdn.self_link
  }

  path_matcher {
    name            = var.gcp_domain
    default_service = google_compute_backend_bucket.gcp_cdn.self_link

    path_rule {
      paths   = ["/*"]
      service = google_compute_backend_bucket.gcp_cdn.self_link
    }
  }
}

resource "google_compute_target_http_proxy" "gcp_cdn" {
  name    = var.gcp_domain
  url_map = google_compute_url_map.gcp_cdn.self_link
}

resource "google_compute_global_forwarding_rule" "gcp_cdn" {
  name       = var.gcp_domain
  target     = google_compute_target_http_proxy.gcp_cdn.self_link
  port_range = "80"
}