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

# Create a VPC on AWS
resource "aws_vpc" "aws_vpc" {
  cidr_block = var.aws_vpc_cidr

  tags = {
    Name = "aws-vpc"
  }
}

# Create subnets on AWS
resource "aws_subnet" "aws_subnet_1" {
  vpc_id            = aws_vpc.aws_vpc.id
  cidr_block        = var.aws_subnet_1_cidr
  availability_zone = var.aws_availability_zone

  tags = {
    Name = "aws-subnet-1"
  }
}

resource "aws_subnet" "aws_subnet_2" {
  vpc_id            = aws_vpc.aws_vpc.id
  cidr_block        = var.aws_subnet_2_cidr
  availability_zone = var.aws_availability_zone

  tags = {
    Name = "aws-subnet-2"
  }
}

# Create a VNet on Azure
resource "azurerm_virtual_network" "azure_vnet" {
  name                = "azure-vnet"
  resource_group_name = var.azure_resource_group_name
  location            = var.azure_location
  address_space       = [var.azure_vnet_cidr]
}

# Create subnets on Azure
resource "azurerm_subnet" "azure_subnet_1" {
  name                 = "azure-subnet-1"
  resource_group_name = var.azure_resource_group_name
  virtual_network_name = azurerm_virtual_network.azure_vnet.name
  address_prefixes     = [var.azure_subnet_1_cidr]
}

resource "azurerm_subnet" "azure_subnet_2" {
  name                 = "azure-subnet-2"
  resource_group_name = var.azure_resource_group_name
  virtual_network_name = azurerm_virtual_network.azure_vnet.name
  address_prefixes     = [var.azure_subnet_2_cidr]
}

# Create a VPC Network on GCP
resource "google_compute_network" "gcp_vpc" {
  name                    = "gcp-vpc"
  auto_create_subnetworks = false
}

# Create subnets on GCP
resource "google_compute_subnetwork" "gcp_subnet_1" {
  name          = "gcp-subnet-1"
  ip_cidr_range = var.gcp_subnet_1_cidr
  network       = google_compute_network.gcp_vpc.id
}

resource "google_compute_subnetwork" "gcp_subnet_2" {
  name          = "gcp-subnet-2"
  ip_cidr_range = var.gcp_subnet_2_cidr
  network       = google_compute_network.gcp_vpc.id
}

variable "aws_region" {
  type        = string
  sensitive   = true
}

variable "aws_vpc_cidr" {
  type        = string
  sensitive   = true
}

variable "aws_subnet_1_cidr" {
  type        = string
  sensitive   = true
}

variable "aws_subnet_2_cidr" {
  type        = string
  sensitive   = true
}

variable "aws_availability_zone" {
  type        = string
  sensitive   = true
}

variable "azure_subscription_id" {
  type        = string
  sensitive   = true
}

variable "azure_client_id" {
  type        = string
  sensitive   = true
}

variable "azure_client_secret" {
  type        = string
  sensitive   = true
}

variable "azure_tenant_id" {
  type        = string
  sensitive   = true
}

variable "azure_resource_group_name" {
  type        = string
  sensitive   = true
}

variable "azure_location" {
  type        = string
  sensitive   = true
}

variable "azure_vnet_cidr" {
  type        = string
  sensitive   = true
}

variable "azure_subnet_1_cidr" {
  type        = string
  sensitive   = true
}

variable "azure_subnet_2_cidr" {
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

variable "gcp_subnet_1_cidr" {
  type        = string
  sensitive   = true
}

variable "gcp_subnet_2_cidr" {
  type        = string
  sensitive   = true
}

output "aws_vpc_id" {
  value       = aws_vpc.aws_vpc.id
  description = "AWS VPC ID"
}

output "aws_subnet_1_id" {
  value       = aws_subnet.aws_subnet_1.id
  description = "AWS Subnet 1 ID"
}

output "aws_subnet_2_id" {
  value       = aws_subnet.aws_subnet_2.id
  description = "AWS Subnet 2 ID"
}

output "azure_vnet_id" {
  value       = azurerm_virtual_network.azure_vnet.id
  description = "Azure VNet ID"
}

output "azure_subnet_1_id" {
  value       = azurerm_subnet.azure_subnet_1.id
  description = "Azure Subnet 1 ID"
}

output "azure_subnet_2_id" {
  value       = azurerm_subnet.azure_subnet_2.id
  description = "Azure Subnet 2 ID"
}

output "gcp_vpc_id" {
  value       = google_compute_network.gcp_vpc.id
  description = "GCP VPC ID"
}

output "gcp_subnet_1_id" {
  value       = google_compute_subnetwork.gcp_subnet_1.id
  description = "GCP Subnet 1 ID"
}

output "gcp_subnet_2_id" {
  value       = google_compute_subnetwork.gcp_subnet_2.id
  description = "GCP Subnet 2 ID"
}