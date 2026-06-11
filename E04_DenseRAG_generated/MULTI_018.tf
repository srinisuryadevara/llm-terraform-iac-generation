# Configure the AWS Provider
provider "aws" {
  region = var.aws_region
}

# Configure the Azure Provider
provider "azurerm" {
  features {}
  subscription_id = var.azure_subscription_id
  client_id      = var.azure_client_id
  client_secret = var.azure_client_secret
  tenant_id      = var.azure_tenant_id
}

# Configure the Google Cloud Provider
provider "google" {
  project = var.gcp_project_id
  region  = var.gcp_region
}

# Create a DNS zone in AWS (Route 53)
resource "aws_route53_zone" "aws_dns_zone" {
  name = var.aws_dns_zone_name
}

# Create a DNS zone in Azure (DNS Zone)
resource "azurerm_dns_zone" "azure_dns_zone" {
  name                = var.azure_dns_zone_name
  resource_group_name = var.azure_resource_group_name
}

# Create a DNS zone in GCP (Cloud DNS)
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

# Store state in a Cloud Storage bucket
terraform {
  backend "gcs" {
    bucket  = var.gcp_state_bucket
    prefix  = "terraform/state/dns"
    project = var.gcp_project_id
  }
}

# Store state in an Azure Storage container
terraform {
  backend "azurerm" {
    resource_group_name = var.azure_resource_group_name
    storage_account_name = var.azure_storage_account_name
    container_name       = var.azure_container_name
    key                  = var.azure_state_key
  }
}

# Store state in an S3 bucket
terraform {
  backend "s3" {
    bucket = var.aws_state_bucket
    key    = "terraform.tfstate"
    region = var.aws_region
  }
}