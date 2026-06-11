# Configure the AWS Provider
provider "aws" {
  region = var.aws_region
}

# Create a VPC
resource "aws_vpc" "example" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "example-vpc"
  }
}

# Create subnets in the VPC
resource "aws_subnet" "example_subnet1" {
  vpc_id            = aws_vpc.example.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-west-2a"
  tags = {
    Name = "example-subnet1"
  }
}

resource "aws_subnet" "example_subnet2" {
  vpc_id            = aws_vpc.example.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-west-2b"
  tags = {
    Name = "example-subnet2"
  }
}

# Configure the Azure Provider
provider "azurerm" {
  features {}
}

# Create a resource group
resource "azurerm_resource_group" "example" {
  name     = "terraform-resourcegroup"
  location = "East Asia"
}

# Create a virtual network
resource "azurerm_virtual_network" "example" {
  name                = "example-vnet"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  address_space       = ["10.1.0.0/16"]
}

# Create subnets in the virtual network
resource "azurerm_subnet" "example_subnet1" {
  name                 = "example-subnet1"
  resource_group_name = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.example.name
  address_prefixes     = ["10.1.1.0/24"]
}

resource "azurerm_subnet" "example_subnet2" {
  name                 = "example-subnet2"
  resource_group_name = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.example.name
  address_prefixes     = ["10.1.2.0/24"]
}

# Configure the Google Cloud Provider
provider "google" {
  project = var.gcp_project
  region  = var.gcp_region
}

# Create a VPC network
module "vpc" {
  source  = "terraform-google-modules/network/google"
  version = "~> 2.5.0"

  project_id   = var.gcp_project
  network_name = "example-vpc"

  subnets = [
    {
      subnet_name   = "example-subnet1"
      subnet_ip     = "10.2.1.0/24"
      subnet_region = var.gcp_region
    },
    {
      subnet_name   = "example-subnet2"
      subnet_ip     = "10.2.2.0/24"
      subnet_region = var.gcp_region
    },
  ]
}