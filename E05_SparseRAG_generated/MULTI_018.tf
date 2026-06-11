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

# AWS Route 53 DNS Zone
data "aws_route53_zone" "aws_dns" {
  name = var.aws_dns_name
}

# Create record in hosted zone for ACM Certificate Domain verification on AWS
resource "aws_route53_record" "aws_cert_validation" {
  for_each = {
    for val in aws_acm_certificate.aws_cert.domain_validation_options : val.domain_name => {
      name   = val.resource_record_name
      record = val.resource_record_value
      type   = val.resource_record_type
    }
  }
  name    = each.value.name
  records = [each.value.record]
  ttl     = 60
  type    = each.value.type
  zone_id = data.aws_route53_zone.aws_dns.zone_id
}

# Create Alias record towards ALB from Route53 on AWS
resource "aws_route53_record" "aws_jenkins" {
  zone_id  = data.aws_route53_zone.aws_dns.zone_id
  name     = join(".", ["jenkins", data.aws_route53_zone.aws_dns.name])
  type     = "A"
  alias {
    name                   = aws_lb.aws_alb.dns_name
    zone_id                = aws_lb.aws_alb.zone_id
    evaluate_target_health = true
  }
}

# Azure DNS Zone
resource "azurerm_private_dns_zone" "azure_dns" {
  name                = var.azure_dns_name
  resource_group_name = var.azure_rg_name
}

# Linking of DNS zones to Virtual Network on Azure
resource "azurerm_private_dns_zone_virtual_network_link" "azure_dns_link" {
  name                  = "${var.prefix}_link_azure_dns"
  resource_group_name   = var.azure_rg_name
  private_dns_zone_name = azurerm_private_dns_zone.azure_dns.name
  virtual_network_id    = var.azure_vnet_id
}

# Google Cloud DNS Zone
resource "google_dns_managed_zone" "gcp_dns" {
  name        = var.gcp_dns_name
  dns_name    = var.gcp_dns_zone
  description = "GCP DNS zone"
}

# Create DNS record on GCP
resource "google_dns_record_set" "gcp_dns_record" {
  name         = google_dns_managed_zone.gcp_dns.dns_name
  type         = "A"
  ttl          = 300
  managed_zone = google_dns_managed_zone.gcp_dns.name
  rrdatas      = [google_compute_address.gcp_address.address]
}

# Create a static IP address on GCP
resource "google_compute_address" "gcp_address" {
  name = "gcp-static-ip"
}

# Create a global forwarding rule on GCP
resource "google_compute_global_forwarding_rule" "gcp_forwarding_rule" {
  name       = "gcp-forwarding-rule"
  target     = google_compute_target_http_proxy.gcp_target_http_proxy.self_link
  port_range = "80"
}

# Create a target HTTP proxy on GCP
resource "google_compute_target_http_proxy" "gcp_target_http_proxy" {
  name    = "gcp-target-http-proxy"
  url_map = google_compute_url_map.gcp_url_map.self_link
}

# Create a URL map on GCP
resource "google_compute_url_map" "gcp_url_map" {
  name            = "gcp-url-map"
  default_service = google_compute_backend_service.gcp_backend_service.self_link
}

# Create a backend service on GCP
resource "google_compute_backend_service" "gcp_backend_service" {
  name        = "gcp-backend-service"
  protocol    = "HTTP"
  timeout_sec = 10
  health_checks = [
    google_compute_health_check.gcp_health_check.self_link
  ]
}

# Create a health check on GCP
resource "google_compute_health_check" "gcp_health_check" {
  name                = "gcp-health-check"
  check_interval_sec  = 1
  timeout_sec         = 1
  healthy_threshold   = 1
  unhealthy_threshold = 10
  http_health_check {
    port = 80
  }
}