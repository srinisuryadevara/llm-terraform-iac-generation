# AWS VPC
provider "aws" {
  region = var.aws_region
}

resource "aws_vpc" "aws_vpc" {
  cidr_block = var.aws_vpc_cidr
}

resource "aws_subnet" "aws_public_subnet" {
  vpc_id            = aws_vpc.aws_vpc.id
  cidr_block        = var.aws_public_subnet_cidr
  availability_zone = var.aws_availability_zone
}

resource "aws_subnet" "aws_private_subnet" {
  vpc_id            = aws_vpc.aws_vpc.id
  cidr_block        = var.aws_private_subnet_cidr
  availability_zone = var.aws_availability_zone
}

# Azure VNet
provider "azurerm" {
  features {}
}

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

resource "azurerm_subnet" "azure_public_subnet" {
  name                 = var.azure_public_subnet_name
  virtual_network_name = azurerm_virtual_network.azure_vnet.name
  resource_group_name  = azurerm_resource_group.azure_resource_group.name
  address_prefixes     = [var.azure_public_subnet_cidr]
}

resource "azurerm_subnet" "azure_private_subnet" {
  name                 = var.azure_private_subnet_name
  virtual_network_name = azurerm_virtual_network.azure_vnet.name
  resource_group_name  = azurerm_resource_group.azure_resource_group.name
  address_prefixes     = [var.azure_private_subnet_cidr]
}

# GCP VPC Network
provider "google" {
  credentials = file(var.gcp_credentials_file)
  project     = var.gcp_project_id
  region      = var.gcp_region
}

resource "google_compute_network" "gcp_vpc" {
  name                    = var.gcp_vpc_name
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "gcp_public_subnet" {
  name          = var.gcp_public_subnet_name
  ip_cidr_range = var.gcp_public_subnet_cidr
  region        = var.gcp_region
  network       = google_compute_network.gcp_vpc.id
}

resource "google_compute_subnetwork" "gcp_private_subnet" {
  name          = var.gcp_private_subnet_name
  ip_cidr_range = var.gcp_private_subnet_cidr
  region        = var.gcp_region
  network       = google_compute_network.gcp_vpc.id
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