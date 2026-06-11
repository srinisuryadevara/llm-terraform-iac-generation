# AWS Provider
provider "aws" {
  region = var.aws_region
}

# Azure Provider
provider "azurerm" {
  features {}
  subscription_id = var.azure_subscription_id
  client_id       = var.azure_client_id
  client_secret   = var.azure_client_secret
  tenant_id       = var.azure_tenant_id
}

# GCP Provider
provider "google" {
  project = var.gcp_project
  region  = var.gcp_region
}

# AWS EC2 Instance
resource "aws_instance" "aws_ec2" {
  ami           = var.aws_ami
  instance_type = var.aws_instance_type
  vpc_security_group_ids = [aws_security_group.aws_sg.id]
  key_name               = var.aws_key_name
  tags = {
    Name = "aws-ec2-instance"
  }
}

# AWS Security Group
resource "aws_security_group" "aws_sg" {
  name        = "aws-sg"
  description = "AWS Security Group"
  vpc_id      = var.aws_vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Azure Linux VM
resource "azurerm_linux_virtual_machine" "azure_vm" {
  name                = "azure-vm"
  resource_group_name = var.azure_resource_group
  location            = var.azure_location
  size                = var.azure_vm_size
  admin_username      = var.azure_admin_username
  admin_password      = var.azure_admin_password
  network_interface_ids = [azurerm_network_interface.azure_nic.id]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }
}

# Azure Network Interface
resource "azurerm_network_interface" "azure_nic" {
  name                = "azure-nic"
  location            = var.azure_location
  resource_group_name = var.azure_resource_group

  ip_configuration {
    name                          = "azure-ip-config"
    subnet_id                     = var.azure_subnet_id
    private_ip_address_allocation = "Dynamic"
  }
}

# GCP Compute Engine Instance
resource "google_compute_instance" "gcp_instance" {
  name         = "gcp-instance"
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