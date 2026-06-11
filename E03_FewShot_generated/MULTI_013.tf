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

# Create a VPC and subnet in AWS
resource "aws_vpc" "aws_vpc" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "aws_subnet" {
  vpc_id            = aws_vpc.aws_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "${var.aws_region}a"
}

# Create a security group in AWS
resource "aws_security_group" "aws_sg" {
  name        = "aws_sg"
  description = "Allow inbound traffic"
  vpc_id      = aws_vpc.aws_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create an EC2 instance in AWS
resource "aws_instance" "aws_instance" {
  ami           = var.aws_ami
  instance_type = var.aws_instance_type
  vpc_security_group_ids = [aws_security_group.aws_sg.id]
  subnet_id = aws_subnet.aws_subnet.id
  key_name               = var.aws_key_name
}

# Create a resource group in Azure
resource "azurerm_resource_group" "azure_rg" {
  name     = "azure-rg"
  location = var.azure_location
}

# Create a virtual network and subnet in Azure
resource "azurerm_virtual_network" "azure_vnet" {
  name                = "azure-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.azure_rg.location
  resource_group_name = azurerm_resource_group.azure_rg.name
}

resource "azurerm_subnet" "azure_subnet" {
  name           = "azure-subnet"
  resource_group_name = azurerm_resource_group.azure_rg.name
  virtual_network_name = azurerm_virtual_network.azure_vnet.name
  address_prefixes = ["10.0.1.0/24"]
}

# Create a network security group in Azure
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
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Create a public IP in Azure
resource "azurerm_public_ip" "azure_public_ip" {
  name                = "azure-public-ip"
  location            = azurerm_resource_group.azure_rg.location
  resource_group_name = azurerm_resource_group.azure_rg.name
  allocation_method   = "Dynamic"
}

# Create a network interface in Azure
resource "azurerm_network_interface" "azure_nic" {
  name                = "azure-nic"
  location            = azurerm_resource_group.azure_rg.location
  resource_group_name = azurerm_resource_group.azure_rg.name

  ip_configuration {
    name                          = "ip-config"
    subnet_id                     = azurerm_subnet.azure_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.azure_public_ip.id
  }
}

# Create a Linux VM in Azure
resource "azurerm_linux_virtual_machine" "azure_vm" {
  name                = "azure-vm"
  location            = azurerm_resource_group.azure_rg.location
  resource_group_name = azurerm_resource_group.azure_rg.name
  size                = var.azure_vm_size

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
}

# Create a VPC and subnet in GCP
resource "google_compute_network" "gcp_vpc" {
  name                    = "gcp-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "gcp_subnet" {
  name          = "gcp-subnet"
  ip_cidr_range = "10.0.1.0/24"
  network       = google_compute_network.gcp_vpc.id
  region        = var.gcp_region
}

# Create a firewall rule in GCP
resource "google_compute_firewall" "gcp_fw" {
  name    = "gcp-fw"
  network = google_compute_network.gcp_vpc.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
}

# Create a Compute Engine instance in GCP
resource "google_compute_instance" "gcp_instance" {
  name         = "gcp-instance"
  machine_type = var.gcp_machine_type
  zone         = "${var.gcp_region}-a"

  boot_disk {
    initialize_params {
      image = var.gcp_image
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.gcp_subnet.id
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

variable "azure_vm_size" {
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

variable "gcp_image" {
  type = string
}