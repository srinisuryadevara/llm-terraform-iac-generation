# Configure the AWS Provider
provider "aws" {
  region = var.aws_region
}

# Configure the Azure Provider
provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
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
  resource_group_name = var.azure_resource_group_name
  location            = var.azure_location
  address_space       = [var.azure_vnet_cidr]
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
  tags = {
    Environment = var.environment
  }
}

# GCP Subnets
resource "google_compute_subnetwork" "gcp_subnet_1" {
  name          = "gcp-subnet-1"
  ip_cidr_range = var.gcp_subnet_1_cidr
  network       = google_compute_network.gcp_vpc.id
  project       = var.gcp_project
  region        = var.gcp_region
  tags = {
    Environment = var.environment
  }
}

resource "google_compute_subnetwork" "gcp_subnet_2" {
  name          = "gcp-subnet-2"
  ip_cidr_range = var.gcp_subnet_2_cidr
  network       = google_compute_network.gcp_vpc.id
  project       = var.gcp_project
  region        = var.gcp_region
  tags = {
    Environment = var.environment
  }
}

variable "aws_vpc_cidr" {
  type = string
}

variable "aws_subnet_1_cidr" {
  type = string
}

variable "aws_subnet_2_cidr" {
  type = string
}

variable "aws_availability_zone" {
  type = string
}

variable "aws_region" {
  type = string
}

variable "azure_vnet_cidr" {
  type = string
}

variable "azure_subnet_1_cidr" {
  type = string
}

variable "azure_subnet_2_cidr" {
  type = string
}

variable "azure_resource_group_name" {
  type = string
}

variable "azure_location" {
  type = string
}

variable "azure_subscription_id" {
  type = string
}

variable "azure_client_id" {
  type = string
}

variable "azure_client_secret" {
  type = string
}

variable "azure_tenant_id" {
  type = string
}

variable "gcp_vpc_cidr" {
  type = string
}

variable "gcp_subnet_1_cidr" {
  type = string
}

variable "gcp_subnet_2_cidr" {
  type = string
}

variable "gcp_project" {
  type = string
}

variable "gcp_region" {
  type = string
}

variable "environment" {
  type = string
}