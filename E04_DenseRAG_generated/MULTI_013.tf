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

variable "azure_vm_size" {
  default = "Standard_DS2_v2"
}

variable "azure_image_publisher" {
  default = "Canonical"
}

variable "azure_image_offer" {
  default = "UbuntuServer"
}

variable "azure_image_sku" {
  default = "16.04-LTS"
}

variable "gcp_project" {
  default = "your-project-id"
}

variable "gcp_region" {
  default = "us-central1"
}

variable "gcp_instance_type" {
  default = "e2-medium"
}

variable "gcp_image" {
  default = "debian-cloud/debian-9"
}

# Create an AWS EC2 instance
resource "aws_instance" "aws_instance" {
  ami           = var.aws_ami
  instance_type = var.aws_instance_type
  tags = {
    Name = "aws-ec2-instance"
  }
}

# Create an Azure Linux VM
resource "azurerm_virtual_machine" "azure_vm" {
  name                  = "azure-linux-vm"
  location              = var.azure_location
  resource_group_name   = "your-resource-group-name"
  vm_size               = var.azure_vm_size

  storage_image_reference {
    publisher = var.azure_image_publisher
    offer     = var.azure_image_offer
    sku       = var.azure_image_sku
    version   = "latest"
  }

  os_profile {
    computer_name  = "azure-linux-vm"
    admin_username = "your-admin-username"
    admin_password = "your-admin-password"
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }
}

# Create a GCP Compute Engine instance
resource "google_compute_instance" "gcp_instance" {
  name         = "gcp-compute-engine-instance"
  machine_type = var.gcp_instance_type
  zone         = "${var.gcp_region}-a"

  boot_disk {
    initialize_params {
      image = var.gcp_image
    }
  }

  network_interface {
    network = "default"
  }
}