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
  dns_name    = var.gcp_dns_zone_name
  description = "GCP Cloud DNS Zone"
}

# Create GCP Network
resource "google_compute_network" "gcp_network" {
  name                    = var.gcp_network_name
  auto_create_subnetworks = false
}

# Create GCP Subnetwork
resource "google_compute_subnetwork" "gcp_subnetwork" {
  name          = var.gcp_subnetwork_name
  ip_cidr_range = var.gcp_subnetwork_cidr
  network       = google_compute_network.gcp_network.id
}

# Create GCP Cloud DNS Record Set
resource "google_dns_record_set" "gcp_dns_record_set" {
  name         = "example.${google_dns_managed_zone.gcp_dns_zone.dns_name}"
  type         = "A"
  ttl          = 300
  managed_zone = google_dns_managed_zone.gcp_dns_zone.name
  rrdatas      = [google_compute_address.gcp_address.address]
}

# Create GCP Compute Address
resource "google_compute_address" "gcp_address" {
  name = var.gcp_address_name
}

# Create Azure DNS Record Set
resource "azurerm_dns_record_set" "azure_dns_record_set" {
  name                = "example"
  resource_group_name = azurerm_resource_group.azure_resource_group.name
  zone_name           = azurerm_dns_zone.azure_dns_zone.name
  type                = "A"
  ttl                 = 300

  arecords {
    ipv4_address = azurerm_public_ip.azure_public_ip.ip_address
  }
}

# Create Azure Public IP
resource "azurerm_public_ip" "azure_public_ip" {
  name                = var.azure_public_ip_name
  resource_group_name = azurerm_resource_group.azure_resource_group.name
  location            = var.azure_location
  allocation_method   = "Dynamic"
}

# Create AWS Route 53 Record Set
resource "aws_route53_record" "aws_dns_record_set" {
  zone_id = aws_route53_zone.aws_dns_zone.id
  name    = "example"
  type    = "A"
  ttl     = 300
  records = [aws_eip.aws_eip.public_ip]
}

# Create AWS EIP
resource "aws_eip" "aws_eip" {
  vpc = true
}

variable "aws_region" {
  type = string
}

variable "aws_dns_zone_name" {
  type = string
}

variable "azure_dns_zone_name" {
  type = string
}

variable "azure_resource_group_name" {
  type = string
}

variable "azure_location" {
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

variable "gcp_network_name" {
  type = string
}

variable "gcp_subnetwork_name" {
  type = string
}

variable "gcp_subnetwork_cidr" {
  type = string
}

variable "gcp_address_name" {
  type = string
}

variable "azure_public_ip_name" {
  type = string
}