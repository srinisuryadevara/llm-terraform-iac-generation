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
resource "aws_subnet" "aws_subnet1" {
  vpc_id            = aws_vpc.aws_vpc.id
  cidr_block        = var.aws_subnet1_cidr
  availability_zone = var.aws_availability_zone
  tags = {
    Name = "aws-subnet1"
  }
}

resource "aws_subnet" "aws_subnet2" {
  vpc_id            = aws_vpc.aws_vpc.id
  cidr_block        = var.aws_subnet2_cidr
  availability_zone = var.aws_availability_zone
  tags = {
    Name = "aws-subnet2"
  }
}

# Create a VNet on Azure
resource "azurerm_virtual_network" "azure_vnet" {
  name                = "azure-vnet"
  address_space       = [var.azure_vnet_cidr]
  location            = var.azure_location
  resource_group_name = var.azure_resource_group
}

# Create subnets on Azure
resource "azurerm_subnet" "azure_subnet1" {
  name                 = "azure-subnet1"
  resource_group_name = var.azure_resource_group
  virtual_network_name = azurerm_virtual_network.azure_vnet.name
  address_prefixes     = [var.azure_subnet1_cidr]
}

resource "azurerm_subnet" "azure_subnet2" {
  name                 = "azure-subnet2"
  resource_group_name = var.azure_resource_group
  virtual_network_name = azurerm_virtual_network.azure_vnet.name
  address_prefixes     = [var.azure_subnet2_cidr]
}

# Create a VPC Network on GCP
resource "google_compute_network" "gcp_vpc" {
  name                    = "gcp-vpc"
  auto_create_subnetworks = false
}

# Create subnets on GCP
resource "google_compute_subnetwork" "gcp_subnet1" {
  name          = "gcp-subnet1"
  ip_cidr_range = var.gcp_subnet1_cidr
  network       = google_compute_network.gcp_vpc.id
}

resource "google_compute_subnetwork" "gcp_subnet2" {
  name          = "gcp-subnet2"
  ip_cidr_range = var.gcp_subnet2_cidr
  network       = google_compute_network.gcp_vpc.id
}

variable "aws_region" {
  type = string
}

variable "aws_vpc_cidr" {
  type = string
}

variable "aws_subnet1_cidr" {
  type = string
}

variable "aws_subnet2_cidr" {
  type = string
}

variable "aws_availability_zone" {
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

variable "azure_location" {
  type = string
}

variable "azure_resource_group" {
  type = string
}

variable "azure_vnet_cidr" {
  type = string
}

variable "azure_subnet1_cidr" {
  type = string
}

variable "azure_subnet2_cidr" {
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

variable "gcp_subnet1_cidr" {
  type = string
}

variable "gcp_subnet2_cidr" {
  type = string
}