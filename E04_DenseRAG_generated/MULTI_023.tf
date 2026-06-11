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
  version = ">= 2.90.0"
  features {}
}

# GCP PROVIDER
provider "google" {
  project = var.gcp_project
  region  = var.gcp_region
}

# VARIABLES
variable "aws_region" {
  default = "us-west-2"
}

variable "aws_instance_type" {
  default = "t2.micro"
}

variable "aws_ami" {
  default = "ami-0c94855ba95c71c99"
}

variable "azure_location" {
  default = "West US"
}

variable "azure_vm_size" {
  default = "Standard_DS2_v2"
}

variable "azure_image" {
  default = {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }
}

variable "gcp_project" {
  default = "your-project-id"
}

variable "gcp_region" {
  default = "us-central1"
}

variable "gcp_machine_type" {
  default = "e2-medium"
}

variable "gcp_image" {
  default = "debian-cloud/debian-9"
}

# AWS EC2 INSTANCE
resource "aws_instance" "aws_instance" {
  ami           = var.aws_ami
  instance_type = var.aws_instance_type
  tags = {
    Name = "aws-ec2-instance"
  }
}

# AZURE LINUX VM
resource "azurerm_resource_group" "azure_resource_group" {
  name     = "azure-resource-group"
  location = var.azure_location
}

resource "azurerm_virtual_network" "azure_virtual_network" {
  name                = "azure-virtual-network"
  address_space       = ["10.0.0.0/16"]
  location            = var.azure_location
  resource_group_name = azurerm_resource_group.azure_resource_group.name
}

resource "azurerm_subnet" "azure_subnet" {
  name                 = "azure-subnet"
  resource_group_name = azurerm_resource_group.azure_resource_group.name
  virtual_network_name = azurerm_virtual_network.azure_virtual_network.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_network_interface" "azure_network_interface" {
  name                = "azure-network-interface"
  location            = var.azure_location
  resource_group_name = azurerm_resource_group.azure_resource_group.name

  ip_configuration {
    name                          = "azure-ip-configuration"
    subnet_id                     = azurerm_subnet.azure_subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "azure_linux_vm" {
  name                = "azure-linux-vm"
  location            = var.azure_location
  resource_group_name = azurerm_resource_group.azure_resource_group.name
  size                = var.azure_vm_size

  network_interface_ids = [
    azurerm_network_interface.azure_network_interface.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = var.azure_image.publisher
    offer     = var.azure_image.offer
    sku       = var.azure_image.sku
    version   = var.azure_image.version
  }
}

# GCP COMPUTE ENGINE INSTANCE
resource "google_compute_instance" "gcp_instance" {
  project      = var.gcp_project
  zone         = "us-central1-a"
  name         = "gcp-compute-engine-instance"
  machine_type = var.gcp_machine_type
  boot_disk {
    initialize_params {
      image = var.gcp_image
    }
  }
  network_interface {
    network = "default"
  }
}