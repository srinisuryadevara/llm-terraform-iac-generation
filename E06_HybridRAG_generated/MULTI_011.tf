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

# AWS VPC
resource "aws_vpc" "aws_vpc" {
  cidr_block = var.aws_vpc_cidr
  tags = {
    Name = "aws-vpc"
  }
}

# AWS Subnets
resource "aws_subnet" "aws_subnet_1" {
  cidr_block = var.aws_subnet_1_cidr
  vpc_id     = aws_vpc.aws_vpc.id
  availability_zone = var.aws_availability_zone
  tags = {
    Name = "aws-subnet-1"
  }
}

resource "aws_subnet" "aws_subnet_2" {
  cidr_block = var.aws_subnet_2_cidr
  vpc_id     = aws_vpc.aws_vpc.id
  availability_zone = var.aws_availability_zone
  tags = {
    Name = "aws-subnet-2"
  }
}

# Azure VNet
resource "azurerm_virtual_network" "azure_vnet" {
  name                = "azure-vnet"
  address_space       = [var.azure_vnet_cidr]
  location            = var.azure_location
  resource_group_name = var.azure_resource_group
}

# Azure Subnets
resource "azurerm_subnet" "azure_subnet_1" {
  name                 = "azure-subnet-1"
  resource_group_name = var.azure_resource_group
  virtual_network_name = azurerm_virtual_network.azure_vnet.name
  address_prefixes     = [var.azure_subnet_1_cidr]
}

resource "azurerm_subnet" "azure_subnet_2" {
  name                 = "azure-subnet-2"
  resource_group_name = var.azure_resource_group
  virtual_network_name = azurerm_virtual_network.azure_vnet.name
  address_prefixes     = [var.azure_subnet_2_cidr]
}

# GCP VPC Network
resource "google_compute_network" "gcp_vpc" {
  name                    = "gcp-vpc"
  auto_create_subnetworks = false
}

# GCP Subnets
resource "google_compute_subnetwork" "gcp_subnet_1" {
  name          = "gcp-subnet-1"
  ip_cidr_range = var.gcp_subnet_1_cidr
  region        = var.gcp_region
  network       = google_compute_network.gcp_vpc.id
}

resource "google_compute_subnetwork" "gcp_subnet_2" {
  name          = "gcp-subnet-2"
  ip_cidr_range = var.gcp_subnet_2_cidr
  region        = var.gcp_region
  network       = google_compute_network.gcp_vpc.id
}

variable "aws_region" {
  type = string
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

variable "azure_location" {
  type = string
}

variable "azure_resource_group" {
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

variable "gcp_project" {
  type = string
}

variable "gcp_region" {
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