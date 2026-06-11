# AWS CloudFront
provider "aws" {
  alias  = "cloudfront"
  region = "us-east-1"
}

variable "aws_domain" {
  type = string
}

resource "aws_cloudfront_origin_access_identity" "aws_cdn" {
  comment = var.aws_domain
}

data "aws_iam_policy_document" "aws_cdn_policy" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.aws_cdn_bucket.arn}/*"]

    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.aws_cdn.iam_arn]
    }
  }

  statement {
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.aws_cdn_bucket.arn]

    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.aws_cdn.iam_arn]
    }
  }
}

resource "aws_s3_bucket" "aws_cdn_bucket" {
  bucket = var.aws_domain
}

resource "aws_s3_bucket_acl" "aws_cdn_bucket_acl" {
  bucket = aws_s3_bucket.aws_cdn_bucket.id
  acl    = "private"
}

resource "aws_s3_bucket_policy" "aws_cdn_bucket_policy" {
  bucket = aws_s3_bucket.aws_cdn_bucket.id
  policy = data.aws_iam_policy_document.aws_cdn_policy.json
}

resource "aws_cloudfront_distribution" "aws_cdn_distribution" {
  origin {
    origin_id   = aws_s3_bucket.aws_cdn_bucket.id
    domain_name = aws_s3_bucket.aws_cdn_bucket.bucket_regional_domain_name
    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.aws_cdn.cloudfront_access_identity_path
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"
  http_version        = "http2"
}

# Azure CDN
provider "azurerm" {
  alias = "azure_cdn"
  features {}
}

variable "azure_domain" {
  type = string
}

resource "azurerm_resource_group" "azure_cdn_resource_group" {
  provider = azurerm.azure_cdn
  name     = "azure-cdn-resource-group"
  location = "canadaeast"
}

resource "azurerm_cdn_profile" "azure_cdn_profile" {
  provider            = azurerm.azure_cdn
  name                = "azure-cdn-profile"
  resource_group_name = azurerm_resource_group.azure_cdn_resource_group.name
  location            = "canadaeast"
  sku                 = "Standard_Microsoft"
}

resource "azurerm_storage_account" "azure_cdn_storage_account" {
  provider                 = azurerm.azure_cdn
  name                     = var.azure_domain
  resource_group_name      = azurerm_resource_group.azure_cdn_resource_group.name
  location                 = "canadaeast"
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

locals {
  azure_host_name = regex("^https://(.*)/$", azurerm_storage_account.azure_cdn_storage_account.primary_web_endpoint)[0]
}

resource "azurerm_cdn_endpoint" "azure_cdn_endpoint" {
  provider            = azurerm.azure_cdn
  name                = "azure-cdn-endpoint"
  profile_name        = azurerm_cdn_profile.azure_cdn_profile.name
  resource_group_name = azurerm_resource_group.azure_cdn_resource_group.name
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

# GCP Cloud CDN
provider "google" {
  alias = "gcp_cdn"
  project = var.gcp_project
  region  = "us-central1"
}

variable "gcp_project" {
  type = string
}

variable "gcp_domain" {
  type = string
}

resource "google_compute_backend_bucket" "gcp_cdn_backend_bucket" {
  provider      = google.gcp_cdn
  name          = var.gcp_domain
  bucket_name   = var.gcp_domain
  enable_cdn    = true
}

resource "google_compute_url_map" "gcp_cdn_url_map" {
  provider = google.gcp_cdn
  name        = "gcp-cdn-url-map"
  default_service = google_compute_backend_bucket.gcp_cdn_backend_bucket.self_link

  host_rule {
    hosts        = [var.gcp_domain]
    service      = google_compute_backend_bucket.gcp_cdn_backend_bucket.self_link
  }

  path_matcher {
    name            = "gcp-cdn-path-matcher"
    default_service = google_compute_backend_bucket.gcp_cdn_backend_bucket.self_link

    path_rule {
      paths   = ["/*"]
      service = google_compute_backend_bucket.gcp_cdn_backend_bucket.self_link
    }
  }
}

resource "google_compute_target_http_proxy" "gcp_cdn_target_http_proxy" {
  provider = google.gcp_cdn
  name        = "gcp-cdn-target-http-proxy"
  url_map     = google_compute_url_map.gcp_cdn_url_map.self_link
}

resource "google_compute_global_forwarding_rule" "gcp_cdn_global_forwarding_rule" {
  provider = google.gcp_cdn
  name       = "gcp-cdn-global-forwarding-rule"
  target     = google_compute_target_http_proxy.gcp_cdn_target_http_proxy.self_link
  port_range = "80"
}