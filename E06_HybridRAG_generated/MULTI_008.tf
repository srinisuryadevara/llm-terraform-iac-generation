terraform {
  required_providers {
    aws = {
      version = ">= 3.45.0"
    }
    azurerm = {
      version = ">= 2.90.0"
    }
    google = {
      version = ">= 3.45.0"
    }
  }
}

# AWS PROVIDER
provider "aws" {
  region = var.aws_region
}

# AZURE PROVIDER
provider "azurerm" {
  features {}
}

# GCP PROVIDER
provider "google" {
  region = var.gcp_region
}

# VARIABLES
variable "aws_region" {
  default = "us-west-2"
}

variable "aws_instance_type" {
  default = "t2.micro"
}

variable "aws_disk_image" {
  default = "ami-0c94855ba95c71c99"
}

variable "aws_vm_address" {
  default = "10.0.0.14"
}

variable "azurerm_region" {
  default = "West US"
}

variable "azurerm_instance_type" {
  default = "Standard_DS2_v2"
}

variable "azurerm_disk_image" {
  default = "Canonical:UbuntuServer:18.04-LTS:latest"
}

variable "azurerm_vm_address" {
  default = "10.10.20.14"
}

variable "gcp_region" {
  default = "us-central1"
}

variable "gcp_instance_type" {
  default = "e2-medium"
}

variable "gcp_disk_image" {
  default = "debian-cloud/debian-9"
}

variable "gcp_vm_address" {
  default = "10.0.0.14"
}

# AWS RESOURCES
resource "aws_instance" "aws-vm" {
  ami           = var.aws_disk_image
  instance_type = var.aws_instance_type
  vpc_security_group_ids = [aws_security_group.aws-sg.id]
  key_name               = "aws-key"
}

resource "aws_security_group" "aws-sg" {
  name        = "aws-sg"
  description = "AWS security group"
  vpc_id      = "vpc-12345678"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# AZURE RESOURCES
resource "azurerm_resource_group" "azurerm-rg" {
  name     = "azurerm-rg"
  location = var.azurerm_region
}

resource "azurerm_virtual_network" "azurerm-vn" {
  name                = "azurerm-vn"
  address_space       = ["10.0.0.0/16"]
  location            = var.azurerm_region
  resource_group_name = azurerm_resource_group.azurerm-rg.name
}

resource "azurerm_subnet" "azurerm-sn" {
  name                 = "azurerm-sn"
  resource_group_name = azurerm_resource_group.azurerm-rg.name
  virtual_network_name = azurerm_virtual_network.azurerm-vn.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_network_interface" "azurerm-ni" {
  name                = "azurerm-ni"
  location            = var.azurerm_region
  resource_group_name = azurerm_resource_group.azurerm-rg.name

  ip_configuration {
    name                          = "azurerm-nic"
    subnet_id                     = azurerm_subnet.azurerm-sn.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "azurerm-vm" {
  name                = "azurerm-vm"
  location            = var.azurerm_region
  resource_group_name = azurerm_resource_group.azurerm-rg.name
  size                = var.azurerm_instance_type

  network_interface_ids = [
    azurerm_network_interface.azurerm-ni.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
}

# GCP RESOURCES
data "google_compute_zones" "available" {
  region = var.gcp_region
}

resource "google_compute_address" "gcp-ip" {
  name = "gcp-vm-ip-${var.gcp_region}"
  region = var.gcp_region
}

resource "google_compute_instance" "gcp-vm" {
  name         = "gcp-vm-${var.gcp_region}"
  machine_type = var.gcp_instance_type
  zone         = data.google_compute_zones.available.names[0]

  boot_disk {
    initialize_params {
      image = var.gcp_disk_image
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.gcp-subnet1.name
    address = var.gcp_vm_address

    access_config {
      # Static IP
      nat_ip = google_compute_address.gcp-ip.address
    }
  }
}

resource "google_compute_subnetwork" "gcp-subnet1" {
  name          = "gcp-subnet1"
  ip_cidr_range = "10.0.0.0/24"
  region        = var.gcp_region
  network       = google_compute_network.gcp-vn.name
}

resource "google_compute_network" "gcp-vn" {
  name                    = "gcp-vn"
  auto_create_subnetworks = false
}