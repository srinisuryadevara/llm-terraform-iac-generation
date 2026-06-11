provider "aws" {
  region = var.aws_region
}

provider "azurerm" {
  features {}
  subscription_id = var.azure_subscription_id
  client_id       = var.azure_client_id
  client_secret   = var.azure_client_secret
  tenant_id       = var.azure_tenant_id
}

provider "google" {
  project = var.gcp_project
  region  = var.gcp_region
}

resource "aws_vpc" "aws_vpc" {
  cidr_block = var.aws_vpc_cidr

  tags = {
    Name = "aws-vpc"
  }
}

resource "aws_subnet" "aws_subnet" {
  vpc_id            = aws_vpc.aws_vpc.id
  cidr_block        = var.aws_subnet_cidr
  availability_zone = var.aws_availability_zone

  tags = {
    Name = "aws-subnet"
  }
}

resource "azurerm_virtual_network" "azure_vnet" {
  name                = "azure-vnet"
  address_space       = [var.azure_vnet_cidr]
  location            = var.azure_location
  resource_group_name = var.azure_resource_group
}

resource "azurerm_subnet" "azure_subnet" {
  name                 = "azure-subnet"
  resource_group_name = var.azure_resource_group
  virtual_network_name = azurerm_virtual_network.azure_vnet.name
  address_prefixes     = [var.azure_subnet_cidr]
}

resource "google_compute_network" "gcp_vpc" {
  name                    = "gcp-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "gcp_subnet" {
  name          = "gcp-subnet"
  ip_cidr_range = var.gcp_subnet_cidr
  network       = google_compute_network.gcp_vpc.id
  region        = var.gcp_region
}

variable "aws_region" {
  type = string
}

variable "aws_vpc_cidr" {
  type = string
}

variable "aws_subnet_cidr" {
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

variable "azure_subnet_cidr" {
  type = string
}

variable "gcp_project" {
  type = string
}

variable "gcp_region" {
  type = string
}

variable "gcp_subnet_cidr" {
  type = string
}