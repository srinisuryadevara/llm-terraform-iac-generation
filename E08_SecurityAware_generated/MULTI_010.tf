# Configure the AWS Provider
provider "aws" {
  region = var.aws_region
}

# Configure the Azure Provider
provider "azurerm" {
  features {}
  subscription_id = var.azure_subscription_id
  client_id       = var.azure_client_id
  client_secret   = var.azure_client_secret
  tenant_id       = var.azure_tenant_id
}

# Configure the GCP Provider
provider "google" {
  project = var.gcp_project
  region  = var.gcp_region
}

# Create AWS Route 53 DNS Zone
resource "aws_route53_zone" "aws_dns_zone" {
  name = var.aws_dns_zone_name

  tags = {
    Environment = var.environment
    Project     = var.project
  }
}

# Create Azure DNS Zone
resource "azurerm_dns_zone" "azure_dns_zone" {
  name                = var.azure_dns_zone_name
  resource_group_name = var.azure_resource_group_name

  tags = {
    Environment = var.environment
    Project     = var.project
  }
}

# Create GCP Cloud DNS Zone
resource "google_dns_managed_zone" "gcp_dns_zone" {
  name        = var.gcp_dns_zone_name
  dns_name    = var.gcp_dns_zone_name
  description = "GCP Cloud DNS Zone"

  labels = {
    Environment = var.environment
    Project     = var.project
  }
}

variable "aws_region" {
  type        = string
  sensitive   = true
  description = "AWS Region"
}

variable "aws_dns_zone_name" {
  type        = string
  sensitive   = true
  description = "AWS DNS Zone Name"
}

variable "azure_subscription_id" {
  type        = string
  sensitive   = true
  description = "Azure Subscription ID"
}

variable "azure_client_id" {
  type        = string
  sensitive   = true
  description = "Azure Client ID"
}

variable "azure_client_secret" {
  type        = string
  sensitive   = true
  description = "Azure Client Secret"
}

variable "azure_tenant_id" {
  type        = string
  sensitive   = true
  description = "Azure Tenant ID"
}

variable "azure_dns_zone_name" {
  type        = string
  sensitive   = true
  description = "Azure DNS Zone Name"
}

variable "azure_resource_group_name" {
  type        = string
  sensitive   = true
  description = "Azure Resource Group Name"
}

variable "gcp_project" {
  type        = string
  sensitive   = true
  description = "GCP Project"
}

variable "gcp_region" {
  type        = string
  sensitive   = true
  description = "GCP Region"
}

variable "gcp_dns_zone_name" {
  type        = string
  sensitive   = true
  description = "GCP DNS Zone Name"
}

variable "environment" {
  type        = string
  sensitive   = true
  description = "Environment"
}

variable "project" {
  type        = string
  sensitive   = true
  description = "Project"
}