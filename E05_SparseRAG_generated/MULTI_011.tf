# Configure the AWS Provider
provider "aws" {
  region = var.aws_region
}

# Create a VPC on AWS
resource "aws_vpc" "aws_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "aws-vpc"
  }
}

# Create subnets on AWS
resource "aws_subnet" "aws_subnet1" {
  vpc_id            = aws_vpc.aws_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = var.aws_availability_zone
  tags = {
    Name = "aws-subnet1"
  }
}

resource "aws_subnet" "aws_subnet2" {
  vpc_id            = aws_vpc.aws_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = var.aws_availability_zone
  tags = {
    Name = "aws-subnet2"
  }
}

# Configure the Azure Provider
provider "azurerm" {
  features {}
}

# Create a resource group on Azure
resource "azurerm_resource_group" "azure_resource_group" {
  name     = "terraform-resourcegroup"
  location = var.azure_location
}

# Create a VNet on Azure
resource "azurerm_virtual_network" "azure_vnet" {
  name                = "example-vnet"
  resource_group_name = azurerm_resource_group.azure_resource_group.name
  location            = azurerm_resource_group.azure_resource_group.location
  address_space       = ["10.1.0.0/16"]
}

# Create subnets on Azure
resource "azurerm_subnet" "azure_subnet1" {
  name                 = "example-subnet1"
  virtual_network_name = azurerm_virtual_network.azure_vnet.name
  resource_group_name  = azurerm_resource_group.azure_resource_group.name
  address_prefixes     = ["10.1.1.0/24"]
}

resource "azurerm_subnet" "azure_subnet2" {
  name                 = "example-subnet2"
  virtual_network_name = azurerm_virtual_network.azure_vnet.name
  resource_group_name  = azurerm_resource_group.azure_resource_group.name
  address_prefixes     = ["10.1.2.0/24"]
}

# Configure the Google Cloud Provider
provider "google" {
  project = var.gcp_project
  region  = var.gcp_region
}

# Create a VPC network on GCP
module "gcp_vpc" {
  source  = "terraform-google-modules/network/google"
  version = "~> 2.5.0"

  project_id   = var.gcp_project
  network_name = "gcp-vpc"

  subnets = [
    {
      subnet_name   = "gcp-subnet1"
      subnet_ip     = "10.2.1.0/24"
      subnet_region = var.gcp_region
    },
    {
      subnet_name   = "gcp-subnet2"
      subnet_ip     = "10.2.2.0/24"
      subnet_region = var.gcp_region
    },
  ]
}

variable "aws_region" {
  type        = string
  description = "AWS region"
}

variable "aws_availability_zone" {
  type        = string
  description = "AWS availability zone"
}

variable "azure_location" {
  type        = string
  description = "Azure location"
}

variable "gcp_project" {
  type        = string
  description = "GCP project"
}

variable "gcp_region" {
  type        = string
  description = "GCP region"
}