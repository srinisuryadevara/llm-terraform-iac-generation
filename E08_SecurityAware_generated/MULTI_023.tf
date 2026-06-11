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
  description = "Allow inbound traffic on port 22 from specific CIDR"
  vpc_id      = aws_vpc.aws_vpc.id

  ingress {
    description = "SSH from specific CIDR"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.aws_ssh_cidr]
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

# Create a resource group and virtual network on Azure
resource "azurerm_resource_group" "azure_rg" {
  name     = "azure-rg"
  location = var.azure_location
  tags = {
    Name        = "azure-rg"
    Environment = var.environment
  }
}

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

# Create a subnet on Azure
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
    source_address_prefix      = var.azure_ssh_cidr
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

  tags = {
    Name        = "azure-vm"
    Environment = var.environment
  }
}

# Create a network interface on Azure
resource "azurerm_network_interface" "azure_nic" {
  name                = "azure-nic"
  location            = azurerm_resource_group.azure_rg.location
  resource_group_name = azurerm_resource_group.azure_rg.name

  ip_configuration {
    name                          = "azure-ip-config"
    subnet_id                     = azurerm_subnet.azure_subnet.id
    private_ip_address_allocation = "Dynamic"
  }

  tags = {
    Name        = "azure-nic"
    Environment = var.environment
  }
}

# Create a network interface security group association on Azure
resource "azurerm_network_interface_security_group_association" "azure_nic_nsg_assoc" {
  network_interface_id      = azurerm_network_interface.azure_nic.id
  network_security_group_id = azurerm_network_security_group.azure_nsg.id
}

# Create a VPC and subnet on GCP
resource "google_compute_network" "gcp_vpc" {
  name                    = "gcp-vpc"
  auto_create_subnetworks = false
  tags = {
    Name        = "gcp-vpc"
    Environment = var.environment
  }
}

resource "google_compute_subnetwork" "gcp_subnet" {
  name          = "gcp-subnet"
  ip_cidr_range = var.gcp_subnet_cidr
  network       = google_compute_network.gcp_vpc.id
  tags = {
    Name        = "gcp-subnet"
    Environment = var.environment
  }
}

# Create a firewall rule on GCP
resource "google_compute_firewall" "gcp_fw" {
  name    = "gcp-fw"
  network = google_compute_network.gcp_vpc.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = [var.gcp_ssh_cidr]
  target_tags   = ["gcp-vm"]
  tags = {
    Name        = "gcp-fw"
    Environment = var.environment
  }
}

# Create a Compute Engine instance on GCP
resource "google_compute_instance" "gcp_vm" {
  name         = "gcp-vm"
  machine_type = var.gcp_machine_type
  zone         = var.gcp_zone

  boot_disk {
    initialize_params {
      image = var.gcp_image
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.gcp_subnet.name
  }

  tags = [
    "gcp-vm",
  ]

  tags = {
    Name        = "gcp-vm"
    Environment = var.environment
  }
}

variable "aws_region" {
  type        = string
  description = "AWS region"
}

variable "aws_vpc_cidr" {
  type        = string
  description = "AWS VPC CIDR"
}

variable "aws_subnet_cidr" {
  type        = string
  description = "AWS subnet CIDR"
}

variable "aws_availability_zone" {
  type        = string
  description = "AWS availability zone"
}

variable "aws_ssh_cidr" {
  type        = string
  description = "AWS SSH CIDR"
}

variable "aws_ami" {
  type        = string
  description = "AWS AMI"
}

variable "aws_instance_type" {
  type        = string
  description = "AWS instance type"
}

variable "aws_key_name" {
  type        = string
  description = "AWS key name"
}

variable "azure_subscription_id" {
  type        = string
  description = "Azure subscription ID"
}

variable "azure_client_id" {
  type        = string
  description = "Azure client ID"
}

variable "azure_client_secret" {
  type        = string
  description = "Azure client secret"
}

variable "azure_tenant_id" {
  type        = string
  description = "Azure tenant ID"
}

variable "azure_location" {
  type        = string
  description = "Azure location"
}

variable "azure_vnet_cidr" {
  type        = string
  description = "Azure VNet CIDR"
}

variable "azure_subnet_cidr" {
  type        = string
  description = "Azure subnet CIDR"
}

variable "azure_ssh_cidr" {
  type        = string
  description = "Azure SSH CIDR"
}

variable "azure_vm_size" {
  type        = string
  description = "Azure VM size"
}

variable "azure_admin_username" {
  type        = string
  description = "Azure