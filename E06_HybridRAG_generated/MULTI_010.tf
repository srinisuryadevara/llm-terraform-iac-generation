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

# Create a variable for the DNS zone name
variable "dns_zone_name" {
  type        = string
  description = "The name of the DNS zone"
}

# Create a variable for the AWS region
variable "aws_region" {
  type        = string
  description = "The AWS region"
}

# Create a variable for the Azure resource group name
variable "azure_resource_group_name" {
  type        = string
  description = "The name of the Azure resource group"
}

# Create a variable for the GCP project
variable "gcp_project" {
  type        = string
  description = "The GCP project"
}

# Create a variable for the GCP region
variable "gcp_region" {
  type        = string
  description = "The GCP region"
}

# Create a Route 53 zone
resource "aws_route53_zone" "aws_dns_zone" {
  name = var.dns_zone_name
}

# Create an Azure DNS zone
resource "azurerm_dns_zone" "azure_dns_zone" {
  name                = var.dns_zone_name
  resource_group_name = var.azure_resource_group_name
}

# Create a Cloud DNS zone
resource "google_dns_managed_zone" "gcp_dns_zone" {
  name        = var.dns_zone_name
  dns_name    = "${var.dns_zone_name}."
  description = "Cloud DNS zone"
}

# Output the DNS zone IDs
output "aws_dns_zone_id" {
  value       = aws_route53_zone.aws_dns_zone.id
  description = "The ID of the AWS DNS zone"
}

output "azure_dns_zone_id" {
  value       = azurerm_dns_zone.azure_dns_zone.id
  description = "The ID of the Azure DNS zone"
}

output "gcp_dns_zone_id" {
  value       = google_dns_managed_zone.gcp_dns_zone.id
  description = "The ID of the GCP DNS zone"
}