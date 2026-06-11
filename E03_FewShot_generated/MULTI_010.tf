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

# Create a variable for the domain name
variable "domain_name" {
  type        = string
  description = "The domain name for the DNS zone"
}

# Create a variable for the AWS region
variable "aws_region" {
  type        = string
  description = "The AWS region for the DNS zone"
}

# Create a variable for the Azure region
variable "azure_region" {
  type        = string
  description = "The Azure region for the DNS zone"
}

# Create a variable for the GCP project
variable "gcp_project" {
  type        = string
  description = "The GCP project for the DNS zone"
}

# Create a variable for the GCP region
variable "gcp_region" {
  type        = string
  description = "The GCP region for the DNS zone"
}

# Create an AWS Route 53 DNS zone
resource "aws_route53_zone" "aws_dns_zone" {
  name = var.domain_name
}

# Create an Azure DNS zone
resource "azurerm_dns_zone" "azure_dns_zone" {
  name                = var.domain_name
  resource_group_name = var.azure_resource_group
}

# Create a variable for the Azure resource group
variable "azure_resource_group" {
  type        = string
  description = "The Azure resource group for the DNS zone"
}

# Create a GCP Cloud DNS zone
resource "google_dns_managed_zone" "gcp_dns_zone" {
  name        = var.domain_name
  dns_name    = "${var.domain_name}."
  description = "GCP Cloud DNS zone for ${var.domain_name}"
}

# Output the DNS zone IDs
output "aws_dns_zone_id" {
  value       = aws_route53_zone.aws_dns_zone.id
  description = "The ID of the AWS Route 53 DNS zone"
}

output "azure_dns_zone_id" {
  value       = azurerm_dns_zone.azure_dns_zone.id
  description = "The ID of the Azure DNS zone"
}

output "gcp_dns_zone_id" {
  value       = google_dns_managed_zone.gcp_dns_zone.id
  description = "The ID of the GCP Cloud DNS zone"
}