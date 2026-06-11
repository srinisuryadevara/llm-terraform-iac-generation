# Configure the AWS Provider
provider "aws" {
  region = var.aws_region
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}

# Create a new VPC in AWS
resource "aws_vpc" "aws_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name        = "aws-vpc"
    Environment = "dev"
  }
}

# Create a new subnet in AWS
resource "aws_subnet" "aws_subnet" {
  vpc_id            = aws_vpc.aws_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-west-2a"
  tags = {
    Name        = "aws-subnet"
    Environment = "dev"
  }
}

# Create a new security group in AWS
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
    cidr_blocks = ["10.0.0.0/16"]
  }
}

# Create a new EC2 instance in AWS
resource "aws_instance" "aws_ec2" {
  ami           = "ami-0c94855ba95c71c99"
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
  client_id      = var.azure_client_id
  client_secret = var.azure_client_secret
  tenant_id      = var.azure_tenant_id
}

# Create a new resource group in Azure
resource "azurerm_resource_group" "azure_rg" {
  name     = "azure-rg"
  location = "West US"
  tags = {
    Environment = "dev"
  }
}

# Create a new virtual network in Azure
resource "azurerm_virtual_network" "azure_vnet" {
  name                = "azure-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.azure_rg.location
  resource_group_name = azurerm_resource_group.azure_rg.name
  tags = {
    Environment = "dev"
  }
}

# Create a new subnet in Azure
resource "azurerm_subnet" "azure_subnet" {
  name                 = "azure-subnet"
  resource_group_name = azurerm_resource_group.azure_rg.name
  virtual_network_name = azurerm_virtual_network.azure_vnet.name
  address_prefixes     = ["10.0.1.0/24"]
  tags = {
    Environment = "dev"
  }
}

# Create a new network security group in Azure
resource "azurerm_network_security_group" "azure_nsg" {
  name                = "azure-nsg"
  location            = azurerm_resource_group.azure_rg.location
  resource_group_name = azurerm_resource_group.azure_rg.name
  tags = {
    Environment = "dev"
  }
}

# Create a new network security rule in Azure
resource "azurerm_network_security_rule" "azure_nsr" {
  name                        = "azure-nsr"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range          = "*"
  destination_port_range     = "22"
  source_address_prefix      = "10.0.0.0/16"
  destination_address_prefix = "10.0.0.0/16"
  resource_group_name         = azurerm_resource_group.azure_rg.name
  network_security_group_name = azurerm_network_security_group.azure_nsg.name
}

# Create a new public IP in Azure
resource "azurerm_public_ip" "azure_public_ip" {
  name                = "azure-public-ip"
  location            = azurerm_resource_group.azure_rg.location
  resource_group_name = azurerm_resource_group.azure_rg.name
  allocation_method   = "Dynamic"
  tags = {
    Environment = "dev"
  }
}

# Create a new network interface in Azure
resource "azurerm_network_interface" "azure_nic" {
  name                = "azure-nic"
  location            = azurerm_resource_group.azure_rg.location
  resource_group_name = azurerm_resource_group.azure_rg.name
  tags = {
    Environment = "dev"
  }

  ip_configuration {
    name                          = "azure-ip-config"
    subnet_id                     = azurerm_subnet.azure_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.azure_public_ip.id
  }
}

# Create a new Linux VM in Azure
resource "azurerm_linux_virtual_machine" "azure_vm" {
  name                = "azure-vm"
  location            = azurerm_resource_group.azure_rg.location
  resource_group_name = azurerm_resource_group.azure_rg.name
  size                = "Standard_DS2_v2"
  tags = {
    Environment = "dev"
  }

  network_interface_ids = [
    azurerm_network_interface.azure_nic.id,
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

# Configure the GCP Provider
provider "google" {
  project = var.gcp_project
  region  = var.gcp_region
  credentials = var.gcp_credentials
}

# Create a new VPC in GCP
resource "google_compute_network" "gcp_vpc" {
  name                    = "gcp-vpc"
  auto_create_subnetworks = false
  labels = {
    Environment = "dev"
  }
}

# Create a new subnet in GCP
resource "google_compute_subnetwork" "gcp_subnet" {
  name          = "gcp-subnet"
  ip_cidr_range = "10.0.1.0/24"
  network       = google_compute_network.gcp_vpc.id
  labels = {
    Environment = "dev"
  }
}

# Create a new firewall rule in GCP
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

  source_ranges = ["10.0.0.0/16"]
}

# Create a new Compute Engine instance in GCP
resource "google_compute_instance" "gcp_instance" {
  name         = "gcp-instance"
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
    subnetwork = google_compute_subnetwork.gcp_subnet.id
  }
}

# Output blocks for key resource attributes
output "aws_vpc_id" {
  value = aws_vpc.aws_vpc.id
}

output "aws_subnet_id" {
  value = aws_subnet.aws_subnet.id
}

output "aws_ec2_id" {
  value = aws_instance.aws_ec2.id
}

output "azure_rg_id" {
  value = azurerm_resource_group.azure_rg.id
}

output "azure_vnet_id" {
  value = azurerm_virtual_network.azure_vnet.id
}

output "azure_subnet_id" {
  value = azurerm_subnet.azure_subnet.id
}

output "azure_vm_id" {
  value = azurerm_linux_virtual_machine.azure_vm.id
}

output "gcp_vpc_id" {
  value = google_compute_network.gcp_vpc.id
}

output "gcp_subnet_id" {
  value = google_compute_subnetwork.gcp_subnet.id
}

output "gcp_instance_id" {
  value = google_compute_instance.gcp_instance.id
}