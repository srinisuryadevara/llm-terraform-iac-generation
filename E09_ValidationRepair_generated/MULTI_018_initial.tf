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

# Create a DNS zone on AWS (Route 53)
resource "aws_route53_zone" "aws_dns_zone" {
  name = var.aws_dns_zone_name
}

# Create a DNS zone on Azure (DNS Zone)
resource "azurerm_dns_zone" "azure_dns_zone" {
  name                = var.azure_dns_zone_name
  resource_group_name = var.azure_resource_group_name
}

# Create a DNS zone on GCP (Cloud DNS)
resource "google_dns_managed_zone" "gcp_dns_zone" {
  name        = var.gcp_dns_zone_name
  dns_name    = var.gcp_dns_zone_name
  description = "GCP DNS zone"
}

# Output the DNS zone IDs
output "aws_dns_zone_id" {
  value = aws_route53_zone.aws_dns_zone.id
}

output "azure_dns_zone_id" {
  value = azurerm_dns_zone.azure_dns_zone.id
}

output "gcp_dns_zone_id" {
  value = google_dns_managed_zone.gcp_dns_zone.id
}

variable "aws_region" {
  type        = string
  sensitive   = true
}

variable "aws_dns_zone_name" {
  type        = string
  sensitive   = true
}

variable "azure_resource_group_name" {
  type        = string
  sensitive   = true
}

variable "azure_dns_zone_name" {
  type        = string
  sensitive   = true
}

variable "gcp_project" {
  type        = string
  sensitive   = true
}

variable "gcp_region" {
  type        = string
  sensitive   = true
}

variable "gcp_dns_zone_name" {
  type        = string
  sensitive   = true
}