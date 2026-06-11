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
resource "aws_subnet" "aws_subnet_1" {
  vpc_id            = aws_vpc.aws_vpc.id
  cidr_block        = var.aws_subnet_1_cidr
  availability_zone = var.aws_availability_zone

  tags = {
    Name        = "aws-subnet-1"
    Environment = var.environment
  }
}

resource "aws_subnet" "aws_subnet_2" {
  vpc_id            = aws_vpc.aws_vpc.id
  cidr_block        = var.aws_subnet_2_cidr
  availability_zone = var.aws_availability_zone

  tags = {
    Name        = "aws-subnet-2"
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
resource "azurerm_subnet" "azure_subnet_1" {
  name                 = "azure-subnet-1"
  resource_group_name = var.azure_resource_group_name
  virtual_network_name = azurerm_virtual_network.azure_vnet.name
  address_prefixes     = [var.azure_subnet_1_cidr]

  delegation {
    name = "delegation"

    service_delegation {
      name    = "Microsoft.ContainerInstance/containerGroups"
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action", "Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action"]
    }
  }
}

resource "azurerm_subnet" "azure_subnet_2" {
  name                 = "azure-subnet-2"
  resource_group_name = var.azure_resource_group_name
  virtual_network_name = azurerm_virtual_network.azure_vnet.name
  address_prefixes     = [var.azure_subnet_2_cidr]
}

# GCP VPC Network
resource "google_compute_network" "gcp_vpc" {
  name                    = "gcp-vpc"
  auto_create_subnetworks = false
  project                 = var.gcp_project

  depends_on = [
    google_project_service.compute,
    google_project_service.network
  ]
}

# GCP Subnets
resource "google_compute_subnetwork" "gcp_subnet_1" {
  name          = "gcp-subnet-1"
  ip_cidr_range = var.gcp_subnet_1_cidr
  network       = google_compute_network.gcp_vpc.id
  project       = var.gcp_project
  region        = var.gcp_region
}

resource "google_compute_subnetwork" "gcp_subnet_2" {
  name          = "gcp-subnet-2"
  ip_cidr_range = var.gcp_subnet_2_cidr
  network       = google_compute_network.gcp_vpc.id
  project       = var.gcp_project
  region        = var.gcp_region
}

# Enable required GCP services
resource "google_project_service" "compute" {
  service = "compute.googleapis.com"
  project = var.gcp_project
}

resource "google_project_service" "network" {
  service = "network.googleapis.com"
  project = var.gcp_project
}

variable "aws_region" {
  type        = string
  description = "AWS Region"
}

variable "aws_vpc_cidr" {
  type        = string
  description = "AWS VPC CIDR"
}

variable "aws_subnet_1_cidr" {
  type        = string
  description = "AWS Subnet 1 CIDR"
}

variable "aws_subnet_2_cidr" {
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

variable "azure_subnet_1_cidr" {
  type        = string
  description = "Azure Subnet 1 CIDR"
}

variable "azure_subnet_2_cidr" {
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

variable "gcp_subnet_1_cidr" {
  type        = string
  description = "GCP Subnet 1 CIDR"
}

variable "gcp_subnet_2_cidr" {
  type        = string
  description = "GCP Subnet 2 CIDR"
}

variable "environment" {
  type        = string
  description = "Environment"
}