# Configure the AWS Provider
provider "aws" {
  region = var.aws_region
}

# Create a VPC in AWS
resource "aws_vpc" "aws_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "aws-vpc"
  }
}

# Create subnets in AWS
resource "aws_subnet" "aws_subnet1" {
  vpc_id            = aws_vpc.aws_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-west-2a"
  tags = {
    Name = "aws-subnet1"
  }
}

resource "aws_subnet" "aws_subnet2" {
  vpc_id            = aws_vpc.aws_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-west-2b"
  tags = {
    Name = "aws-subnet2"
  }
}

# Configure the Azure Provider
provider "azurerm" {
  features {}
}

# Create a resource group in Azure
resource "azurerm_resource_group" "azure_rg" {
  name     = "terraform-resourcegroup"
  location = "East Asia"
}

# Create a virtual network in Azure
resource "azurerm_virtual_network" "azure_vnet" {
  name                = "example-vnet"
  resource_group_name = azurerm_resource_group.azure_rg.name
  location            = azurerm_resource_group.azure_rg.location
  address_space       = ["10.1.0.0/16"]
}

# Create subnets in Azure
resource "azurerm_subnet" "azure_subnet1" {
  name                 = "example-subnet1"
  virtual_network_name = azurerm_virtual_network.azure_vnet.name
  resource_group_name  = azurerm_resource_group.azure_rg.name
  address_prefixes     = ["10.1.1.0/24"]
}

resource "azurerm_subnet" "azure_subnet2" {
  name                 = "example-subnet2"
  virtual_network_name = azurerm_virtual_network.azure_vnet.name
  resource_group_name  = azurerm_resource_group.azure_rg.name
  address_prefixes     = ["10.1.2.0/24"]
}

# Configure the Google Cloud Provider
provider "google" {
  project = var.gcp_project
  region  = var.gcp_region
}

# Create a VPC network in GCP
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