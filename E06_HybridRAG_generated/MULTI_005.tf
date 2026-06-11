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
  credentials = file(var.gcp_credentials_file)
  project     = var.gcp_project
  region      = var.gcp_region
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
  availability_zone = var.aws_availability_zone_1
  tags = {
    Name = "aws-subnet-1"
  }
}

resource "aws_subnet" "aws_subnet_2" {
  vpc_id            = aws_vpc.aws_vpc.id
  cidr_block        = var.aws_subnet_2_cidr
  availability_zone = var.aws_availability_zone_2
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
  type        = string
  default     = "us-west-2"
}

variable "aws_vpc_cidr" {
  type        = string
  default     = "10.0.0.0/16"
}

variable "aws_subnet_1_cidr" {
  type        = string
  default     = "10.0.1.0/24"
}

variable "aws_subnet_2_cidr" {
  type        = string
  default     = "10.0.2.0/24"
}

variable "aws_availability_zone_1" {
  type        = string
  default     = "us-west-2a"
}

variable "aws_availability_zone_2" {
  type        = string
  default     = "us-west-2b"
}

variable "azure_resource_group_name" {
  type        = string
  default     = "example-resource-group"
}

variable "azure_location" {
  type        = string
  default     = "West US"
}

variable "azure_vnet_cidr" {
  type        = string
  default     = "10.1.0.0/16"
}

variable "azure_subnet_1_cidr" {
  type        = string
  default     = "10.1.1.0/24"
}

variable "azure_subnet_2_cidr" {
  type        = string
  default     = "10.1.2.0/24"
}

variable "gcp_credentials_file" {
  type        = string
  sensitive   = true
}

variable "gcp_project" {
  type        = string
  default     = "example-project"
}

variable "gcp_region" {
  type        = string
  default     = "us-west2"
}

variable "gcp_subnet_1_cidr" {
  type        = string
  default     = "10.2.1.0/24"
}

variable "gcp_subnet_2_cidr" {
  type        = string
  default     = "10.2.2.0/24"
}