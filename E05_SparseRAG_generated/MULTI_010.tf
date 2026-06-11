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
  name                  = "${var.prefix}_link_azure"
  resource_group_name   = var.azure_rg_name
  private_dns_zone_name = azurerm_private_dns_zone.azure_dns.name
  virtual_network_id    = var.azure_vnet_id
}

# GCP Cloud DNS Zone
resource "google_dns_managed_zone" "gcp_dns" {
  name        = var.gcp_dns_name
  dns_name    = var.gcp_dns_zone
  description = "GCP Cloud DNS Zone"
}

# Store state in a Cloud Storage bucket on GCP
terraform {
  backend "gcs" {
    bucket  = var.gcp_bucket
    prefix  = "terraform/state/dns"
    project = var.gcp_project
  }
}

variable "aws_region" {
  type = string
}

variable "aws_dns_name" {
  type = string
}

variable "aws_cert" {
  type = object({
    domain_validation_options = list(object({
      domain_name = string
      resource_record_name = string
      resource_record_type = string
      resource_record_value = string
    }))
  })
}

variable "azure_rg_name" {
  type = string
}

variable "azure_dns_name" {
  type = string
}

variable "azure_vnet_id" {
  type = string
}

variable "gcp_project" {
  type = string
}

variable "gcp_region" {
  type = string
}

variable "gcp_bucket" {
  type = string
}

variable "gcp_dns_name" {
  type = string
}

variable "gcp_dns_zone" {
  type = string
}

variable "prefix" {
  type = string
}