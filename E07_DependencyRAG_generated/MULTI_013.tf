# Configure the AWS Provider
provider "aws" {
  region = var.aws_region
}

# Create a VPC
resource "aws_vpc" "aws_vpc" {
  cidr_block = var.aws_vpc_cidr
}

# Create a subnet
resource "aws_subnet" "aws_subnet" {
  vpc_id            = aws_vpc.aws_vpc.id
  cidr_block        = var.aws_subnet_cidr
  availability_zone = var.aws_availability_zone
}

# Create a security group
resource "aws_security_group" "aws_sg" {
  name        = var.aws_sg_name
  description = var.aws_sg_description
  vpc_id      = aws_vpc.aws_vpc.id

  ingress {
    description = "Allow SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create an EC2 instance
resource "aws_instance" "aws_instance" {
  ami           = var.aws_ami
  instance_type = var.aws_instance_type
  subnet_id     = aws_subnet.aws_subnet.id
  vpc_security_group_ids = [
    aws_security_group.aws_sg.id
  ]
  key_name = var.aws_key_name
}

# Configure the Azure Provider
provider "azurerm" {
  features {}
}

# Create a resource group
resource "azurerm_resource_group" "azurerm_rg" {
  name     = var.azurerm_rg_name
  location = var.azurerm_location
}

# Create a virtual network
resource "azurerm_virtual_network" "azurerm_vnet" {
  name                = var.azurerm_vnet_name
  resource_group_name = azurerm_resource_group.azurerm_rg.name
  location            = azurerm_resource_group.azurerm_rg.location
  address_space       = [var.azurerm_vnet_cidr]
}

# Create a subnet
resource "azurerm_subnet" "azurerm_subnet" {
  name                 = var.azurerm_subnet_name
  resource_group_name = azurerm_resource_group.azurerm_rg.name
  virtual_network_name = azurerm_virtual_network.azurerm_vnet.name
  address_prefixes     = [var.azurerm_subnet_cidr]
}

# Create a network security group
resource "azurerm_network_security_group" "azurerm_nsg" {
  name                = var.azurerm_nsg_name
  resource_group_name = azurerm_resource_group.azurerm_rg.name
  location            = azurerm_resource_group.azurerm_rg.location
}

# Create a network security rule
resource "azurerm_network_security_rule" "azurerm_nsr" {
  name                        = var.azurerm_nsr_name
  resource_group_name         = azurerm_resource_group.azurerm_rg.name
  network_security_group_name = azurerm_network_security_group.azurerm_nsg.name
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range          = "*"
  destination_port_range     = "22"
  source_address_prefix      = "*"
  destination_address_prefix = "*"
}

# Create a network interface
resource "azurerm_network_interface" "azurerm_nic" {
  name                = var.azurerm_nic_name
  resource_group_name = azurerm_resource_group.azurerm_rg.name
  location            = azurerm_resource_group.azurerm_rg.location

  ip_configuration {
    name                          = var.azurerm_ip_config_name
    subnet_id                     = azurerm_subnet.azurerm_subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

# Create a Linux virtual machine
resource "azurerm_linux_virtual_machine" "azurerm_vm" {
  name                = var.azurerm_vm_name
  resource_group_name = azurerm_resource_group.azurerm_rg.name
  location            = azurerm_resource_group.azurerm_rg.location
  size                = var.azurerm_vm_size

  network_interface_ids = [
    azurerm_network_interface.azurerm_nic.id,
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

# Configure the Google Cloud Provider
provider "google" {
  project = var.gcp_project
  region  = var.gcp_region
}

# Create a VPC
resource "google_compute_network" "gcp_vpc" {
  name                    = var.gcp_vpc_name
  auto_create_subnetworks = false
}

# Create a subnet
resource "google_compute_subnetwork" "gcp_subnet" {
  name          = var.gcp_subnet_name
  region        = var.gcp_region
  network       = google_compute_network.gcp_vpc.self_link
  ip_cidr_range = var.gcp_subnet_cidr
}

# Create a firewall rule
resource "google_compute_firewall" "gcp_fw" {
  name    = var.gcp_fw_name
  network = google_compute_network.gcp_vpc.self_link

  allow {
    protocol = "tcp"
    ports    = ["22", "80"]
  }

  source_ranges = ["0.0.0.0/0"]
}

# Create a Compute Engine instance
resource "google_compute_instance" "gcp_instance" {
  name         = var.gcp_instance_name
  zone         = "${var.gcp_region}-b"
  machine_type = var.gcp_machine_type

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.gcp_subnet.self_link
    access_config {
    }
  }

  metadata = {
    ssh-keys = "ubuntu:${chomp(tls_private_key.ssh-key.public_key_openssh)} terraform"
  }

  tags = ["http-server"]
}

# Create a TLS private key
resource "tls_private_key" "ssh-key" {
  algorithm = "ED25519"
}