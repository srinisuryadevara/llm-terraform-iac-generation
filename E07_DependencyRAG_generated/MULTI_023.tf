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
resource "aws_security_group" "aws_security_group" {
  vpc_id = aws_vpc.aws_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
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
    aws_security_group.aws_security_group.id
  ]
  key_name = var.aws_key_name
}

# Configure the Azure Provider
provider "azurerm" {
  features {}
}

# Create a resource group
resource "azurerm_resource_group" "azurerm_resource_group" {
  name     = var.azurerm_resource_group_name
  location = var.azurerm_location
}

# Create a virtual network
resource "azurerm_virtual_network" "azurerm_virtual_network" {
  name                = var.azurerm_virtual_network_name
  resource_group_name = azurerm_resource_group.azurerm_resource_group.name
  location            = azurerm_resource_group.azurerm_resource_group.location
  address_space       = [var.azurerm_virtual_network_address_space]
}

# Create a subnet
resource "azurerm_subnet" "azurerm_subnet" {
  name                 = var.azurerm_subnet_name
  resource_group_name = azurerm_resource_group.azurerm_resource_group.name
  virtual_network_name = azurerm_virtual_network.azurerm_virtual_network.name
  address_prefixes     = [var.azurerm_subnet_address_prefix]
}

# Create a network security group
resource "azurerm_network_security_group" "azurerm_network_security_group" {
  name                = var.azurerm_network_security_group_name
  resource_group_name = azurerm_resource_group.azurerm_resource_group.name
  location            = azurerm_resource_group.azurerm_resource_group.location
}

# Create a network security rule
resource "azurerm_network_security_rule" "azurerm_network_security_rule" {
  name                        = var.azurerm_network_security_rule_name
  resource_group_name         = azurerm_resource_group.azurerm_resource_group.name
  network_security_group_name = azurerm_network_security_group.azurerm_network_security_group.name
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range          = "*"
  destination_port_range     = "22"
  source_address_prefix      = "*"
  destination_address_prefix = "*"
}

resource "azurerm_network_security_rule" "azurerm_network_security_rule_http" {
  name                        = var.azurerm_network_security_rule_http_name
  resource_group_name         = azurerm_resource_group.azurerm_resource_group.name
  network_security_group_name = azurerm_network_security_group.azurerm_network_security_group.name
  priority                    = 101
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range          = "*"
  destination_port_range     = "80"
  source_address_prefix      = "*"
  destination_address_prefix = "*"
}

# Create a public IP
resource "azurerm_public_ip" "azurerm_public_ip" {
  name                = var.azurerm_public_ip_name
  resource_group_name = azurerm_resource_group.azurerm_resource_group.name
  location            = azurerm_resource_group.azurerm_resource_group.location
  allocation_method   = "Dynamic"
}

# Create a network interface
resource "azurerm_network_interface" "azurerm_network_interface" {
  name                = var.azurerm_network_interface_name
  resource_group_name = azurerm_resource_group.azurerm_resource_group.name
  location            = azurerm_resource_group.azurerm_resource_group.location

  ip_configuration {
    name                          = var.azurerm_ip_configuration_name
    subnet_id                     = azurerm_subnet.azurerm_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.azurerm_public_ip.id
  }
}

# Associate the network security group with the network interface
resource "azurerm_network_interface_security_group_association" "azurerm_network_interface_security_group_association" {
  network_interface_id      = azurerm_network_interface.azurerm_network_interface.id
  network_security_group_id = azurerm_network_security_group.azurerm_network_security_group.id
}

# Create a Linux virtual machine
resource "azurerm_linux_virtual_machine" "azurerm_linux_virtual_machine" {
  name                = var.azurerm_linux_virtual_machine_name
  resource_group_name = azurerm_resource_group.azurerm_resource_group.name
  location            = azurerm_resource_group.azurerm_resource_group.location
  size                = var.azurerm_linux_virtual_machine_size

  network_interface_ids = [
    azurerm_network_interface.azurerm_network_interface.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = var.azurerm_source_image_reference_publisher
    offer     = var.azurerm_source_image_reference_offer
    sku       = var.azurerm_source_image_reference_sku
    version   = var.azurerm_source_image_reference_version
  }
}

# Configure the Google Cloud Provider
provider "google" {
  project = var.google_project
  region  = var.google_region
}

# Create a VPC
resource "google_compute_network" "google_compute_network" {
  name                    = var.google_compute_network_name
  auto_create_subnetworks = false
}

# Create a subnet
resource "google_compute_subnetwork" "google_compute_subnetwork" {
  name          = var.google_compute_subnetwork_name
  region        = var.google_region
  network       = google_compute_network.google_compute_network.self_link
  ip_cidr_range = var.google_compute_subnetwork_ip_cidr_range
}

# Create a firewall rule
resource "google_compute_firewall" "google_compute_firewall" {
  name    = var.google_compute_firewall_name
  network = google_compute_network.google_compute_network.self_link

  allow {
    protocol = "tcp"
    ports    = ["22", "80"]
  }

  source_ranges = ["0.0.0.0/0"]
}

# Create a compute instance
resource "google_compute_instance" "google_compute_instance" {
  name         = var.google_compute_instance_name
  zone         = "${var.google_region}-b"
  machine_type = var.google_machine_type

  boot_disk {
    initialize_params {
      image = var.google_image
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.google_compute_subnetwork.self_link
    access_config {
    }
  }

  metadata = {
    ssh-keys = "ubuntu:${chomp(tls_private_key.ssh-key.public_key_openssh)} terraform"
  }

  tags = ["http-server"]
}

# Create a private key
resource "tls_private_key" "ssh-key" {
  algorithm = "ED25519"
}