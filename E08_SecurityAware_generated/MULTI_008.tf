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

# Create a VPC and subnet on AWS
resource "aws_vpc" "aws_vpc" {
  cidr_block = var.aws_vpc_cidr
  tags = {
    Name        = "aws-vpc"
    Environment = var.environment
  }
}

resource "aws_subnet" "aws_subnet" {
  cidr_block = var.aws_subnet_cidr
  vpc_id     = aws_vpc.aws_vpc.id
  availability_zone = var.aws_availability_zone
  tags = {
    Name        = "aws-subnet"
    Environment = var.environment
  }
}

# Create a security group on AWS
resource "aws_security_group" "aws_sg" {
  name        = "aws-sg"
  description = "Allow inbound traffic on port 22 from a specific CIDR"
  vpc_id      = aws_vpc.aws_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.aws_sg_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "aws-sg"
    Environment = var.environment
  }
}

# Create an EC2 instance on AWS
resource "aws_instance" "aws_ec2" {
  ami           = var.aws_ami
  instance_type = var.aws_instance_type
  vpc_security_group_ids = [aws_security_group.aws_sg.id]
  subnet_id = aws_subnet.aws_subnet.id
  key_name               = var.aws_key_name
  tags = {
    Name        = "aws-ec2"
    Environment = var.environment
  }
}

# Create a resource group on Azure
resource "azurerm_resource_group" "azure_rg" {
  name     = "azure-rg"
  location = var.azure_location
  tags = {
    Name        = "azure-rg"
    Environment = var.environment
  }
}

# Create a virtual network and subnet on Azure
resource "azurerm_virtual_network" "azure_vnet" {
  name                = "azure-vnet"
  address_space       = [var.azure_vnet_cidr]
  location            = azurerm_resource_group.azure_rg.location
  resource_group_name = azurerm_resource_group.azure_rg.name
  tags = {
    Name        = "azure-vnet"
    Environment = var.environment
  }
}

resource "azurerm_subnet" "azure_subnet" {
  name                 = "azure-subnet"
  resource_group_name = azurerm_resource_group.azure_rg.name
  virtual_network_name = azurerm_virtual_network.azure_vnet.name
  address_prefixes     = [var.azure_subnet_cidr]
  tags = {
    Name        = "azure-subnet"
    Environment = var.environment
  }
}

# Create a network security group on Azure
resource "azurerm_network_security_group" "azure_nsg" {
  name                = "azure-nsg"
  location            = azurerm_resource_group.azure_rg.location
  resource_group_name = azurerm_resource_group.azure_rg.name

  security_rule {
    name                       = "SSH"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = var.azure_nsg_cidr
    destination_address_prefix = "*"
  }

  tags = {
    Name        = "azure-nsg"
    Environment = var.environment
  }
}

# Create a Linux VM on Azure
resource "azurerm_linux_virtual_machine" "azure_vm" {
  name                = "azure-vm"
  resource_group_name = azurerm_resource_group.azure_rg.name
  location            = azurerm_resource_group.azure_rg.location
  size                = var.azure_vm_size
  admin_username      = var.azure_admin_username
  admin_password      = var.azure_admin_password
  network_interface_ids = [azurerm_network_interface.azure_nic.id]
  tags = {
    Name        = "azure-vm"
    Environment = var.environment
  }
}

resource "azurerm_network_interface" "azure_nic" {
  name                = "azure-nic"
  location            = azurerm_resource_group.azure_rg.location
  resource_group_name = azurerm_resource_group.azure_rg.name

  ip_configuration {
    name                          = "ipconfig"
    subnet_id                     = azurerm_subnet.azure_subnet.id
    private_ip_address_allocation = "Dynamic"
  }

  tags = {
    Name        = "azure-nic"
    Environment = var.environment
  }
}

# Create a network on GCP
resource "google_compute_network" "gcp_network" {
  name                    = "gcp-network"
  auto_create_subnetworks = false
  tags = {
    Name        = "gcp-network"
    Environment = var.environment
  }
}

# Create a subnet on GCP
resource "google_compute_subnetwork" "gcp_subnet" {
  name          = "gcp-subnet"
  ip_cidr_range = var.gcp_subnet_cidr
  network       = google_compute_network.gcp_network.id
  region        = var.gcp_region
  tags = {
    Name        = "gcp-subnet"
    Environment = var.environment
  }
}

# Create a firewall rule on GCP
resource "google_compute_firewall" "gcp_fw" {
  name    = "gcp-fw"
  network = google_compute_network.gcp_network.id

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = [var.gcp_fw_cidr]
  tags = {
    Name        = "gcp-fw"
    Environment = var.environment
  }
}

# Create a Compute Engine instance on GCP
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
    subnetwork = google_compute_subnetwork.gcp_subnet.id
  }

  tags = [
    "gcp-instance",
    var.environment,
  ]
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

variable "aws_sg_cidr" {
  type = string
}

variable "aws_ami" {
  type = string
}

variable "aws_instance_type" {
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

variable "azure_location" {
  type = string
}

variable "azure_vnet_cidr" {
  type = string
}

variable "azure_subnet_cidr" {
  type = string
}

variable "azure_nsg_cidr" {
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

variable "gcp_project" {
  type = string
}

variable "gcp_region" {
  type = string
}

variable "gcp_zone" {
  type = string
}

variable "gcp_subnet_cidr" {
  type = string
}

variable "gcp_fw_cidr" {
  type = string
}

variable "gcp_machine_type" {
  type = string
}

variable "gcp_image" {
  type = string
}

variable "environment" {
  type = string
}