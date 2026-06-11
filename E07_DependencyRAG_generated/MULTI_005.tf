# Configure the AWS Provider
provider "aws" {
  region = var.aws_region
}

# Create a VPC on AWS
resource "aws_vpc" "aws_vpc" {
  cidr_block = var.aws_vpc_cidr
}

# Create a subnet on AWS
resource "aws_subnet" "aws_subnet" {
  vpc_id            = aws_vpc.aws_vpc.id
  cidr_block        = var.aws_subnet_cidr
  availability_zone = var.aws_availability_zone
}

# Configure the Azure Provider
provider "azurerm" {
  features {}
}

# Create a resource group on Azure
resource "azurerm_resource_group" "azure_resource_group" {
  name     = var.azure_resource_group_name
  location = var.azure_location
}

# Create a virtual network on Azure
resource "azurerm_virtual_network" "azure_vnet" {
  name                = var.azure_vnet_name
  resource_group_name = azurerm_resource_group.azure_resource_group.name
  location            = azurerm_resource_group.azure_resource_group.location
  address_space       = [var.azure_vnet_cidr]
}

# Create a subnet on Azure
resource "azurerm_subnet" "azure_subnet" {
  name                 = var.azure_subnet_name
  virtual_network_name = azurerm_virtual_network.azure_vnet.name
  resource_group_name  = azurerm_resource_group.azure_resource_group.name
  address_prefixes     = [var.azure_subnet_cidr]
}

# Configure the Google Cloud Provider
provider "google" {
  project = var.gcp_project
  region  = var.gcp_region
}

# Create a VPC network on GCP
resource "google_compute_network" "gcp_vpc" {
  name                    = var.gcp_vpc_name
  auto_create_subnetworks = false
}

# Create a subnet on GCP
resource "google_compute_subnetwork" "gcp_subnet" {
  name          = var.gcp_subnet_name
  ip_cidr_range = var.gcp_subnet_cidr
  region        = var.gcp_region
  network       = google_compute_network.gcp_vpc.id
}