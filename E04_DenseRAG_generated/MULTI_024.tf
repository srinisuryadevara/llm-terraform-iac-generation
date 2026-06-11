# Configure the AWS Provider
provider "aws" {
  region = var.aws_region
}

# Configure the Azure Provider
provider "azurerm" {
  features {}
}

# Configure the Google Cloud Provider
provider "google" {
  credentials = file(var.gcp_credentials_file)
  project     = var.gcp_project
  region      = var.gcp_region
}

# AWS VPC
resource "aws_vpc" "aws_vpc" {
  cidr_block = var.aws_vpc_cidr
  tags = {
    Name = "aws-vpc"
  }
}

# AWS Subnet
resource "aws_subnet" "aws_subnet" {
  cidr_block = var.aws_subnet_cidr
  vpc_id     = aws_vpc.aws_vpc.id
  availability_zone = var.aws_availability_zone
  tags = {
    Name = "aws-subnet"
  }
}

# Azure VNet
resource "azurerm_resource_group" "azure_resource_group" {
  name     = var.azure_resource_group_name
  location = var.azure_location
}

resource "azurerm_virtual_network" "azure_vnet" {
  name                = var.azure_vnet_name
  resource_group_name = azurerm_resource_group.azure_resource_group.name
  location            = azurerm_resource_group.azure_resource_group.location
  address_space       = [var.azure_vnet_cidr]
}

# Azure Subnet
resource "azurerm_subnet" "azure_subnet" {
  name                 = var.azure_subnet_name
  resource_group_name = azurerm_resource_group.azure_resource_group.name
  virtual_network_name = azurerm_virtual_network.azure_vnet.name
  address_prefixes     = [var.azure_subnet_cidr]
}

# GCP VPC Network
resource "google_compute_network" "gcp_vpc" {
  name                    = var.gcp_vpc_name
  auto_create_subnetworks = false
}

# GCP Subnet
resource "google_compute_subnetwork" "gcp_subnet" {
  name          = var.gcp_subnet_name
  ip_cidr_range = var.gcp_subnet_cidr
  region        = var.gcp_region
  network       = google_compute_network.gcp_vpc.id
}

variable "aws_region" {
  type        = string
  description = "AWS Region"
}

variable "aws_vpc_cidr" {
  type        = string
  description = "AWS VPC CIDR"
}

variable "aws_subnet_cidr" {
  type        = string
  description = "AWS Subnet CIDR"
}

variable "aws_availability_zone" {
  type        = string
  description = "AWS Availability Zone"
}

variable "azure_resource_group_name" {
  type        = string
  description = "Azure Resource Group Name"
}

variable "azure_location" {
  type        = string
  description = "Azure Location"
}

variable "azure_vnet_name" {
  type        = string
  description = "Azure VNet Name"
}

variable "azure_vnet_cidr" {
  type        = string
  description = "Azure VNet CIDR"
}

variable "azure_subnet_name" {
  type        = string
  description = "Azure Subnet Name"
}

variable "azure_subnet_cidr" {
  type        = string
  description = "Azure Subnet CIDR"
}

variable "gcp_credentials_file" {
  type        = string
  description = "GCP Credentials File"
}

variable "gcp_project" {
  type        = string
  description = "GCP Project"
}

variable "gcp_region" {
  type        = string
  description = "GCP Region"
}

variable "gcp_vpc_name" {
  type        = string
  description = "GCP VPC Name"
}

variable "gcp_subnet_name" {
  type        = string
  description = "GCP Subnet Name"
}

variable "gcp_subnet_cidr" {
  type        = string
  description = "GCP Subnet CIDR"
}