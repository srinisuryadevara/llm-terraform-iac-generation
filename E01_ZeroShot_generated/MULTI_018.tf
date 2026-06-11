# Configure the AWS Provider
provider "aws" {
  region = var.aws_region
}

# Configure the Azure Provider
provider "azurerm" {
  features {}
}

# Configure the GCP Provider
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
  resource_group_name = var.azure_resource_group_name
}

# Create GCP Cloud DNS Zone
resource "google_dns_managed_zone" "gcp_dns_zone" {
  name        = var.gcp_dns_zone_name
  dns_name    = var.gcp_dns_zone_name
  description = "GCP Cloud DNS Zone"
}

# Output DNS Zone IDs
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