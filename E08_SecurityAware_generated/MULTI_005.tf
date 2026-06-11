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

# AWS VPC
resource "aws_vpc" "aws_vpc" {
  cidr_block = var.aws_vpc_cidr
  tags = {
    Name        = "aws-vpc"
    Environment = var.environment
  }
}

# AWS Subnets
resource "aws_subnet" "aws_subnet1" {
  vpc_id            = aws_vpc.aws_vpc.id
  cidr_block        = var.aws_subnet1_cidr
  availability_zone = var.aws_availability_zone
  tags = {
    Name        = "aws-subnet1"
    Environment = var.environment
  }
}

resource "aws_subnet" "aws_subnet2" {
  vpc_id            = aws_vpc.aws_vpc.id
  cidr_block        = var.aws_subnet2_cidr
  availability_zone = var.aws_availability_zone
  tags = {
    Name        = "aws-subnet2"
    Environment = var.environment
  }
}

# Azure VNet
resource "azurerm_virtual_network" "azure_vnet" {
  name                = "azure-vnet"
  address_space       = [var.azure_vnet_cidr]
  location            = var.azure_location
  resource_group_name = var.azure_resource_group_name
  tags = {
    Environment = var.environment
  }
}

# Azure Subnets
resource "azurerm_subnet" "azure_subnet1" {
  name                 = "azure-subnet1"
  resource_group_name = var.azure_resource_group_name
  virtual_network_name = azurerm_virtual_network.azure_vnet.name
  address_prefixes     = [var.azure_subnet1_cidr]
}

resource "azurerm_subnet" "azure_subnet2" {
  name                 = "azure-subnet2"
  resource_group_name = var.azure_resource_group_name
  virtual_network_name = azurerm_virtual_network.azure_vnet.name
  address_prefixes     = [var.azure_subnet2_cidr]
}

# GCP VPC Network
resource "google_compute_network" "gcp_vpc" {
  name                    = "gcp-vpc"
  auto_create_subnetworks = false
  project                 = var.gcp_project
  tags = {
    Environment = var.environment
  }
}

# GCP Subnets
resource "google_compute_subnetwork" "gcp_subnet1" {
  name          = "gcp-subnet1"
  ip_cidr_range = var.gcp_subnet1_cidr
  network       = google_compute_network.gcp_vpc.id
  project       = var.gcp_project
  region        = var.gcp_region
  tags = {
    Environment = var.environment
  }
}

resource "google_compute_subnetwork" "gcp_subnet2" {
  name          = "gcp-subnet2"
  ip_cidr_range = var.gcp_subnet2_cidr
  network       = google_compute_network.gcp_vpc.id
  project       = var.gcp_project
  region        = var.gcp_region
  tags = {
    Environment = var.environment
  }
}

variable "aws_region" {
  type        = string
  description = "AWS Region"
}

variable "aws_vpc_cidr" {
  type        = string
  description = "AWS VPC CIDR"
}

variable "aws_subnet1_cidr" {
  type        = string
  description = "AWS Subnet 1 CIDR"
}

variable "aws_subnet2_cidr" {
  type        = string
  description = "AWS Subnet 2 CIDR"
}

variable "aws_availability_zone" {
  type        = string
  description = "AWS Availability Zone"
}

variable "azure_subscription_id" {
  type        = string
  description = "Azure Subscription ID"
}

variable "azure_client_id" {
  type        = string
  description = "Azure Client ID"
}

variable "azure_client_secret" {
  type        = string
  description = "Azure Client Secret"
}

variable "azure_tenant_id" {
  type        = string
  description = "Azure Tenant ID"
}

variable "azure_location" {
  type        = string
  description = "Azure Location"
}

variable "azure_resource_group_name" {
  type        = string
  description = "Azure Resource Group Name"
}

variable "azure_vnet_cidr" {
  type        = string
  description = "Azure VNet CIDR"
}

variable "azure_subnet1_cidr" {
  type        = string
  description = "Azure Subnet 1 CIDR"
}

variable "azure_subnet2_cidr" {
  type        = string
  description = "Azure Subnet 2 CIDR"
}

variable "gcp_project" {
  type        = string
  description = "GCP Project"
}

variable "gcp_region" {
  type        = string
  description = "GCP Region"
}

variable "gcp_vpc_cidr" {
  type        = string
  description = "GCP VPC CIDR"
}

variable "gcp_subnet1_cidr" {
  type        = string
  description = "GCP Subnet 1 CIDR"
}

variable "gcp_subnet2_cidr" {
  type        = string
  description = "GCP Subnet 2 CIDR"
}

variable "environment" {
  type        = string
  description = "Environment"
}