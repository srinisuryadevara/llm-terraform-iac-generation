# Configure the AWS Provider
provider "aws" {
  region = var.aws_region
}

# Configure the Azure Provider
provider "azurerm" {
  features {}
}

# Configure the Google Provider
provider "google" {
  project = var.gcp_project
  region  = var.gcp_region
}

# Create AWS Route 53 DNS Zone
resource "aws_route53_zone" "aws_dns_zone" {
  name = var.aws_dns_zone_name
}

# Create Azure DNS Zone
resource "azurerm_dns_zone" "azure_dns_zone" {
  name                = var.azure_dns_zone_name
  resource_group_name = azurerm_resource_group.azure_resource_group.name
}

# Create Azure Resource Group
resource "azurerm_resource_group" "azure_resource_group" {
  name     = var.azure_resource_group_name
  location = var.azure_location
}

# Create GCP Cloud DNS Zone
resource "google_dns_managed_zone" "gcp_dns_zone" {
  name        = var.gcp_dns_zone_name
  dns_name    = var.gcp_dns_zone_domain
  description = "GCP Cloud DNS Zone"
}

# Create GCP Project
# resource "google_project" "gcp_project" {
#   project_id      = var.gcp_project_id
#   name            = var.gcp_project_name
#   billing_account = var.gcp_billing_account
# }

# Create AWS Route 53 Record Set
resource "aws_route53_record" "aws_record_set" {
  zone_id = aws_route53_zone.aws_dns_zone.id
  name    = var.aws_record_set_name
  type    = var.aws_record_set_type
  ttl     = var.aws_record_set_ttl
  records = [var.aws_record_set_value]
}

# Create Azure DNS Record Set
resource "azurerm_dns_txt_record" "azure_record_set" {
  name                = var.azure_record_set_name
  zone_name           = azurerm_dns_zone.azure_dns_zone.name
  resource_group_name = azurerm_resource_group.azure_resource_group.name
  ttl                 = var.azure_record_set_ttl

  record {
    value = var.azure_record_set_value
  }
}

# Create GCP Cloud DNS Record Set
resource "google_dns_record_set" "gcp_record_set" {
  name         = var.gcp_record_set_name
  type         = var.gcp_record_set_type
  ttl          = var.gcp_record_set_ttl
  managed_zone = google_dns_managed_zone.gcp_dns_zone.name

  rrdatas = [var.gcp_record_set_value]
}

variable "aws_region" {
  type = string
}

variable "aws_dns_zone_name" {
  type = string
}

variable "aws_record_set_name" {
  type = string
}

variable "aws_record_set_type" {
  type = string
}

variable "aws_record_set_ttl" {
  type = number
}

variable "aws_record_set_value" {
  type = string
}

variable "azure_location" {
  type = string
}

variable "azure_resource_group_name" {
  type = string
}

variable "azure_dns_zone_name" {
  type = string
}

variable "azure_record_set_name" {
  type = string
}

variable "azure_record_set_ttl" {
  type = number
}

variable "azure_record_set_value" {
  type = string
}

variable "gcp_project" {
  type = string
}

variable "gcp_region" {
  type = string
}

variable "gcp_dns_zone_name" {
  type = string
}

variable "gcp_dns_zone_domain" {
  type = string
}

variable "gcp_record_set_name" {
  type = string
}

variable "gcp_record_set_type" {
  type = string
}

variable "gcp_record_set_ttl" {
  type = number
}

variable "gcp_record_set_value" {
  type = string
}