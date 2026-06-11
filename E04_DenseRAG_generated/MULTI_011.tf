# Configure the AWS Provider
provider "aws" {
  region = var.aws_region
}

# Create a VPC
resource "aws_vpc" "main" {
  cidr_block = var.aws_vpc_cidr
  tags = {
    Name = "main-vpc"
  }
}

# Create a public subnet
resource "aws_subnet" "public" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.aws_public_subnet_cidr
  availability_zone = var.aws_availability_zone
  tags = {
    Name = "public-subnet"
  }
}

# Create a private subnet
resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.aws_private_subnet_cidr
  availability_zone = var.aws_availability_zone
  tags = {
    Name = "private-subnet"
  }
}

# Configure the Azure Provider
provider "azurerm" {
  features {}
}

# Create a resource group
resource "azurerm_resource_group" "example" {
  name     = var.azure_resource_group_name
  location = var.azure_location
}

# Create a virtual network
resource "azurerm_virtual_network" "example-vnet" {
  name                = var.azure_vnet_name
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  address_space       = [var.azure_vnet_cidr]
}

# Create a public subnet
resource "azurerm_subnet" "public" {
  name                 = var.azure_public_subnet_name
  virtual_network_name = azurerm_virtual_network.example-vnet.name
  resource_group_name  = azurerm_resource_group.example.name
  address_prefixes     = [var.azure_public_subnet_cidr]
}

# Create a private subnet
resource "azurerm_subnet" "private" {
  name                 = var.azure_private_subnet_name
  virtual_network_name = azurerm_virtual_network.example-vnet.name
  resource_group_name  = azurerm_resource_group.example.name
  address_prefixes     = [var.azure_private_subnet_cidr]
}

# Configure the Google Cloud Provider
provider "google" {
  credentials = file(var.gcp_credentials_file)
  project     = var.gcp_project_id
  region      = var.gcp_region
}

# Create a VPC network
resource "google_compute_network" "main" {
  name                    = var.gcp_vpc_name
  auto_create_subnetworks = false
}

# Create a public subnet
resource "google_compute_subnetwork" "public" {
  name          = var.gcp_public_subnet_name
  ip_cidr_range = var.gcp_public_subnet_cidr
  region        = var.gcp_region
  network       = google_compute_network.main.id
}

# Create a private subnet
resource "google_compute_subnetwork" "private" {
  name          = var.gcp_private_subnet_name
  ip_cidr_range = var.gcp_private_subnet_cidr
  region        = var.gcp_region
  network       = google_compute_network.main.id
}

variable "aws_region" {
  type = string
}

variable "aws_vpc_cidr" {
  type = string
}

variable "aws_public_subnet_cidr" {
  type = string
}

variable "aws_private_subnet_cidr" {
  type = string
}

variable "aws_availability_zone" {
  type = string
}

variable "azure_resource_group_name" {
  type = string
}

variable "azure_location" {
  type = string
}

variable "azure_vnet_name" {
  type = string
}

variable "azure_vnet_cidr" {
  type = string
}

variable "azure_public_subnet_name" {
  type = string
}

variable "azure_public_subnet_cidr" {
  type = string
}

variable "azure_private_subnet_name" {
  type = string
}

variable "azure_private_subnet_cidr" {
  type = string
}

variable "gcp_credentials_file" {
  type = string
}

variable "gcp_project_id" {
  type = string
}

variable "gcp_region" {
  type = string
}

variable "gcp_vpc_name" {
  type = string
}

variable "gcp_public_subnet_name" {
  type = string
}

variable "gcp_public_subnet_cidr" {
  type = string
}

variable "gcp_private_subnet_name" {
  type = string
}

variable "gcp_private_subnet_cidr" {
  type = string
}