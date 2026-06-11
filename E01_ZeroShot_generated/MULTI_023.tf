# Configure the AWS Provider
provider "aws" {
  region = var.aws_region
}

# Configure the Azure Provider
provider "azurerm" {
  features {}
  subscription_id = var.azure_subscription_id
  client_id       = var.azure_client_id
  client_secret   = var.azure_client_secret
  tenant_id       = var.azure_tenant_id
}

# Configure the GCP Provider
provider "google" {
  project = var.gcp_project
  region  = var.gcp_region
}

# Create a new AWS EC2 instance
resource "aws_instance" "example" {
  ami           = var.aws_ami
  instance_type = var.aws_instance_type
  vpc_security_group_ids = [aws_security_group.example.id]
  key_name               = var.aws_key_name
}

# Create a new security group for the AWS EC2 instance
resource "aws_security_group" "example" {
  name        = "example-sg"
  description = "Example security group"
  vpc_id      = var.aws_vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create a new Azure Linux VM
resource "azurerm_linux_virtual_machine" "example" {
  name                = "example-vm"
  resource_group_name = var.azure_resource_group
  location            = var.azure_location
  size                = var.azure_vm_size

  admin_username = var.azure_admin_username
  admin_password = var.azure_admin_password
  disable_password_authentication = false

  network_interface_ids = [azurerm_network_interface.example.id]
}

# Create a new Azure network interface
resource "azurerm_network_interface" "example" {
  name                = "example-nic"
  resource_group_name = var.azure_resource_group
  location            = var.azure_location

  ip_configuration {
    name                          = "example-config"
    subnet_id                     = var.azure_subnet_id
    private_ip_address_allocation = "Dynamic"
  }
}

# Create a new GCP Compute Engine instance
resource "google_compute_instance" "example" {
  name         = "example-instance"
  machine_type = var.gcp_machine_type
  zone         = var.gcp_zone

  boot_disk {
    initialize_params {
      image = var.gcp_image
    }
  }

  network_interface {
    network = var.gcp_network
  }
}

variable "aws_region" {
  type = string
}

variable "aws_ami" {
  type = string
}

variable "aws_instance_type" {
  type = string
}

variable "aws_vpc_id" {
  type = string
}

variable "aws_key_name" {
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

variable "azure_resource_group" {
  type = string
}

variable "azure_location" {
  type = string
}

variable "azure_vm_size" {
  type = string
}

variable "azure_admin_username" {
  type = string
}

variable "azure_admin_password" {
  type = string
}

variable "azure_subnet_id" {
  type = string
}

variable "gcp_project" {
  type = string
}

variable "gcp_region" {
  type = string
}

variable "gcp_machine_type" {
  type = string
}

variable "gcp_zone" {
  type = string
}

variable "gcp_image" {
  type = string
}

variable "gcp_network" {
  type = string
}