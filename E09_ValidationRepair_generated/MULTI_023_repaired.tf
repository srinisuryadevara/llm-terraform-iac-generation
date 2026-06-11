# Configure the AWS Provider
provider "aws" {
  region = var.aws_region
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}

# Create a new VPC on AWS
resource "aws_vpc" "aws_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name        = "aws-vpc"
    Environment = "dev"
  }
}

# Create a new subnet on AWS
resource "aws_subnet" "aws_subnet" {
  vpc_id            = aws_vpc.aws_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-west-2a"
  tags = {
    Name        = "aws-subnet"
    Environment = "dev"
  }
}

# Create a new security group on AWS
resource "aws_security_group" "aws_sg" {
  name        = "aws_sg"
  description = "Allow inbound traffic on port 22"
  vpc_id      = aws_vpc.aws_vpc.id
  tags = {
    Name        = "aws-sg"
    Environment = "dev"
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["192.168.1.0/24"] # restrict CIDR
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create a new EC2 instance on AWS
resource "aws_instance" "aws_ec2" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.aws_subnet.id
  vpc_security_group_ids = [aws_security_group.aws_sg.id]
  key_name               = var.aws_key_name
  tags = {
    Name        = "aws-ec2"
    Environment = "dev"
  }
}

# Configure the Azure Provider
provider "azurerm" {
  features {}
  subscription_id = var.azure_subscription_id
  client_id       = var.azure_client_id
  client_secret   = var.azure_client_secret
  tenant_id       = var.azure_tenant_id
}

# Create a new resource group on Azure
resource "azurerm_resource_group" "azure_rg" {
  name     = "azure-rg"
  location = "West US"
  tags = {
    Environment = "dev"
  }
}

# Create a new virtual network on Azure
resource "azurerm_virtual_network" "azure_vnet" {
  name                = "azure-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.azure_rg.location
  resource_group_name = azurerm_resource_group.azure_rg.name
  tags = {
    Environment = "dev"
  }
}

# Create a new subnet on Azure
resource "azurerm_subnet" "azure_subnet" {
  name           = "azure-subnet"
  resource_group_name = azurerm_resource_group.azure_rg.name
  virtual_network_name = azurerm_virtual_network.azure_vnet.name
  address_prefixes = ["10.0.1.0/24"]
  tags = {
    Environment = "dev"
  }
}

# Create a new network security group on Azure
resource "azurerm_network_security_group" "azure_nsg" {
  name                = "azure-nsg"
  location            = azurerm_resource_group.azure_rg.location
  resource_group_name = azurerm_resource_group.azure_rg.name
  tags = {
    Environment = "dev"
  }

  security_rule {
    name                       = "SSH"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "192.168.1.0/24" # restrict CIDR
    destination_address_prefix = "*"
  }
}

# Create a new network interface on Azure
resource "azurerm_network_interface" "azure_nic" {
  name                = "azure-nic"
  location            = azurerm_resource_group.azure_rg.location
  resource_group_name = azurerm_resource_group.azure_rg.name
  tags = {
    Environment = "dev"
  }

  ip_configuration {
    name                          = "ip-config"
    subnet_id                     = azurerm_subnet.azure_subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

# Create a new Linux VM on Azure
resource "azurerm_linux_virtual_machine" "azure_vm" {
  name                = "azure-vm"
  location            = azurerm_resource_group.azure_rg.location
  resource_group_name = azurerm_resource_group.azure_rg.name
  size                = "Standard_DS2_v2"
  tags = {
    Environment = "dev"
  }

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

# Configure the GCP Provider
provider "google" {
  project = var.gcp_project
  region  = var.gcp_region
  credentials = file(var.gcp_credentials)
}

# Create a new VPC on GCP
resource "google_compute_network" "gcp_vpc" {
  name                    = "gcp-vpc"
  auto_create_subnetworks = false
  labels = {
    Environment = "dev"
  }
}

# Create a new subnet on GCP
resource "google_compute_subnetwork" "gcp_subnet" {
  name          = "gcp-subnet"
  ip_cidr_range = "10.0.1.0/24"
  network       = google_compute_network.gcp_vpc.id
  labels = {
    Environment = "dev"
  }
}

# Create a new firewall rule on GCP
resource "google_compute_firewall" "gcp_fw" {
  name    = "gcp-fw"
  network = google_compute_network.gcp_vpc.id
  labels = {
    Environment = "dev"
  }

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["192.168.1.0/24"] # restrict CIDR
}

# Create a new Compute Engine instance on GCP
resource "google_compute_instance" "gcp_vm" {
  name         = "gcp-vm"
  machine_type = "f1-micro"
  zone         = "us-west1-a"
  labels = {
    Environment = "dev"
  }

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-9"
    }
  }

  network_interface {
    network = google_compute_network.gcp_vpc.id
    subnetwork = google_compute_subnetwork.gcp_subnet.id
  }
}

# Output blocks for key resource attributes
output "aws_ec2_id" {
  value = aws_instance.aws_ec2.id
}

output "aws_ec2_public_ip" {
  value = aws_instance.aws_ec2.public_ip
}

output "azure_vm_id" {
  value = azurerm_linux_virtual_machine.azure_vm.id
}

output "azure_vm_private_ip" {
  value = azurerm_network_interface.azure_nic.private_ip_address
}

output "gcp_vm_id" {
  value = google_compute_instance.gcp_vm.id
}

output "gcp_vm_internal_ip" {
  value = google_compute_instance.gcp_vm.network_interface[0].network_ip
}