# Configure the AWS Provider
provider "aws" {
  region = var.aws_region
}

# Configure the Azure Provider
provider "azurerm" {
  version = ">= 2.34.0"
  features {}
}

# Configure the Google Cloud Provider
provider "google" {
  project = var.gcp_project
  region  = var.gcp_region
}

# Variables
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

variable "azure_instance_type" {
  default = "Standard_DS2_v2"
}

variable "azure_image" {
  default = {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
}

variable "gcp_project" {
  default = "your-project-id"
}

variable "gcp_region" {
  default = "us-central1"
}

variable "gcp_instance_type" {
  default = "n1-standard-1"
}

variable "gcp_image" {
  default = "debian-cloud/debian-9"
}

# AWS EC2 Instance
resource "aws_instance" "aws-ec2" {
  ami           = var.aws_ami
  instance_type = var.aws_instance_type
  tags = {
    Name = "aws-ec2-instance"
  }
}

# Azure Linux VM
resource "azurerm_resource_group" "azure-rg" {
  name     = "azure-rg"
  location = var.azure_location
}

resource "azurerm_virtual_network" "azure-vnet" {
  name                = "azure-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = var.azure_location
  resource_group_name = azurerm_resource_group.azure-rg.name
}

resource "azurerm_subnet" "azure-subnet" {
  name                 = "azure-subnet"
  resource_group_name = azurerm_resource_group.azure-rg.name
  virtual_network_name = azurerm_virtual_network.azure-vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_network_interface" "azure-nic" {
  name                = "azure-nic"
  location            = var.azure_location
  resource_group_name = azurerm_resource_group.azure-rg.name

  ip_configuration {
    name                          = "ip-config"
    subnet_id                     = azurerm_subnet.azure-subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "azure-vm" {
  name                = "azure-vm"
  location            = var.azure_location
  resource_group_name = azurerm_resource_group.azure-rg.name
  size                = var.azure_instance_type

  network_interface_ids = [
    azurerm_network_interface.azure-nic.id,
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

# GCP Compute Engine Instance
resource "google_compute_instance" "gcp-vm" {
  name         = "gcp-vm"
  machine_type = var.gcp_instance_type
  zone         = "us-central1-a"

  boot_disk {
    initialize_params {
      image = var.gcp_image
    }
  }

  network_interface {
    network = "default"
  }
}