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

# AWS VPC and Subnets
resource "aws_vpc" "aws_vpc" {
  cidr_block = var.aws_vpc_cidr

  tags = {
    Name = "aws-vpc"
  }
}

resource "aws_subnet" "aws_subnet1" {
  cidr_block = var.aws_subnet1_cidr
  vpc_id     = aws_vpc.aws_vpc.id
  availability_zone = var.aws_availability_zone

  tags = {
    Name = "aws-subnet1"
  }
}

resource "aws_subnet" "aws_subnet2" {
  cidr_block = var.aws_subnet2_cidr
  vpc_id     = aws_vpc.aws_vpc.id
  availability_zone = var.aws_availability_zone

  tags = {
    Name = "aws-subnet2"
  }
}

# Azure VNet and Subnets
resource "azurerm_virtual_network" "azure_vnet" {
  name                = "azure-vnet"
  address_space       = [var.azure_vnet_cidr]
  location            = var.azure_location
  resource_group_name = var.azure_resource_group_name
}

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

# GCP VPC Network and Subnets
resource "google_compute_network" "gcp_vpc" {
  name                    = "gcp-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "gcp_subnet1" {
  name          = "gcp-subnet1"
  ip_cidr_range = var.gcp_subnet1_cidr
  network       = google_compute_network.gcp_vpc.id
  region        = var.gcp_region
}

resource "google_compute_subnetwork" "gcp_subnet2" {
  name          = "gcp-subnet2"
  ip_cidr_range = var.gcp_subnet2_cidr
  network       = google_compute_network.gcp_vpc.id
  region        = var.gcp_region
}

# Variables
variable "aws_region" {
  type        = string
  sensitive   = true
}

variable "aws_vpc_cidr" {
  type        = string
  sensitive   = true
}

variable "aws_subnet1_cidr" {
  type        = string
  sensitive   = true
}

variable "aws_subnet2_cidr" {
  type        = string
  sensitive   = true
}

variable "aws_availability_zone" {
  type        = string
  sensitive   = true
}

variable "azure_location" {
  type        = string
  sensitive   = true
}

variable "azure_resource_group_name" {
  type        = string
  sensitive   = true
}

variable "azure_vnet_cidr" {
  type        = string
  sensitive   = true
}

variable "azure_subnet1_cidr" {
  type        = string
  sensitive   = true
}

variable "azure_subnet2_cidr" {
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

variable "gcp_subnet1_cidr" {
  type        = string
  sensitive   = true
}

variable "gcp_subnet2_cidr" {
  type        = string
  sensitive   = true
}