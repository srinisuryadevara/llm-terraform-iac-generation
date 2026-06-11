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

variable "aws_key_name" {
  default = "my-aws-key"
}

variable "azurerm_subscription_id" {}
variable "azurerm_client_id" {}
variable "azurerm_client_secret" {}
variable "azurerm_tenant_id" {}
variable "azurerm_resource_group_name" {}
variable "azurerm_location" {
  default = "West US"
}

variable "azurerm_instance_type" {
  default = "Standard_DS2_v2"
}

variable "gcp_project" {}
variable "gcp_region" {
  default = "us-central1"
}

variable "gcp_instance_type" {
  default = "e2-medium"
}

variable "gcp_image" {
  default = "debian-cloud/debian-9"
}

# AWS EC2 Instance
resource "aws_instance" "aws-ec2" {
  ami           = var.aws_ami
  instance_type = var.aws_instance_type
  key_name               = var.aws_key_name
  vpc_security_group_ids = [aws_security_group.aws-sg.id]
}

# AWS Security Group
resource "aws_security_group" "aws-sg" {
  name        = "aws-sg"
  description = "AWS Security Group"

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
resource "azurerm_resource_group" "azurerm-rg" {
  name     = var.azurerm_resource_group_name
  location = var.azurerm_location
}

resource "azurerm_virtual_network" "azurerm-vn" {
  name                = "azurerm-vn"
  address_space       = ["10.0.0.0/16"]
  location            = var.azurerm_location
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
  location            = var.azurerm_location
  resource_group_name = azurerm_resource_group.azurerm-rg.name

  ip_configuration {
    name                          = "azurerm-ip"
    subnet_id                     = azurerm_subnet.azurerm-sn.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "azurerm-vm" {
  name                = "azurerm-vm"
  location            = var.azurerm_location
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
    sku       = "16.04-LTS"
    version   = "latest"
  }
}

# Azure Provider Configuration
provider "azurerm" {
  alias                   = "azurerm-config"
  version                 = ">= 2.34.0"
  subscription_id         = var.azurerm_subscription_id
  client_id               = var.azurerm_client_id
  client_secret           = var.azurerm_client_secret
  tenant_id               = var.azurerm_tenant_id
  features {}
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