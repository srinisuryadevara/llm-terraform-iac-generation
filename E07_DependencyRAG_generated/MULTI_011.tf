# AWS VPC
provider "aws" {
  region = var.aws_region
}

resource "aws_vpc" "aws_vpc" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "aws_subnet_1" {
  vpc_id            = aws_vpc.aws_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = var.aws_availability_zone
}

resource "aws_subnet" "aws_subnet_2" {
  vpc_id            = aws_vpc.aws_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = var.aws_availability_zone
}

# Azure VNet
provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "azurerm_resource_group" {
  name     = "terraform-resourcegroup"
  location = var.azurerm_location
}

resource "azurerm_virtual_network" "azurerm_vnet" {
  name                = "example-vnet"
  resource_group_name = azurerm_resource_group.azurerm_resource_group.name
  location            = azurerm_resource_group.azurerm_resource_group.location
  address_space       = ["10.1.0.0/16"]
}

resource "azurerm_subnet" "azurerm_subnet_1" {
  name                 = "example-subnet-1"
  virtual_network_name = azurerm_virtual_network.azurerm_vnet.name
  resource_group_name  = azurerm_resource_group.azurerm_resource_group.name
  address_prefixes     = ["10.1.1.0/24"]
}

resource "azurerm_subnet" "azurerm_subnet_2" {
  name                 = "example-subnet-2"
  virtual_network_name = azurerm_virtual_network.azurerm_vnet.name
  resource_group_name  = azurerm_resource_group.azurerm_resource_group.name
  address_prefixes     = ["10.1.2.0/24"]
}

# GCP VPC Network
provider "google" {
  project = var.gcp_project
  region  = var.gcp_region
}

resource "google_compute_network" "gcp_vpc" {
  name                    = "example-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "gcp_subnet_1" {
  name          = "example-subnet-1"
  ip_cidr_range = "10.2.1.0/24"
  region        = var.gcp_region
  network       = google_compute_network.gcp_vpc.id
}

resource "google_compute_subnetwork" "gcp_subnet_2" {
  name          = "example-subnet-2"
  ip_cidr_range = "10.2.2.0/24"
  region        = var.gcp_region
  network       = google_compute_network.gcp_vpc.id
}

variable "aws_region" {
  type        = string
  default     = "us-west-2"
}

variable "aws_availability_zone" {
  type        = string
  default     = "us-west-2a"
}

variable "azurerm_location" {
  type        = string
  default     = "East Asia"
}

variable "gcp_project" {
  type        = string
  default     = "example-project"
}

variable "gcp_region" {
  type        = string
  default     = "us-west2"
}