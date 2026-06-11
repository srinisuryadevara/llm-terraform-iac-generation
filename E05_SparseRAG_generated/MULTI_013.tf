# VARIABLES
variable "aws_region" {
  default = "us-west-2"
}

variable "aws_instance_type" {
  default = "t2.micro"
}

variable "aws_ami" {
  default = "ami-0c94855ba95c71c99"
}

variable "aws_key_pair_name" {
  default = "aws-key-pair"
}

variable "aws_public_key" {
  default = file("~/.ssh/id_rsa.pub")
}

variable "azure_region" {
  default = "West US"
}

variable "azure_instance_type" {
  default = "Standard_DS2_v2"
}

variable "azure_image_publisher" {
  default = "Canonical"
}

variable "azure_image_offer" {
  default = "UbuntuServer"
}

variable "azure_image_sku" {
  default = "18.04-LTS"
}

variable "azure_image_version" {
  default = "latest"
}

variable "gcp_region" {
  default = "us-central1"
}

variable "gcp_instance_type" {
  default = "n1-standard-1"
}

variable "gcp_image" {
  default = "debian-cloud/debian-9"
}

variable "gcp_key_pair_name" {
  default = "gcp-key-pair"
}

variable "gcp_public_key" {
  default = file("~/.ssh/id_rsa.pub")
}

# PROVIDERS
provider "aws" {
  version = "~> 3.0"
  region  = var.aws_region
}

provider "azurerm" {
  version = "~> 2.0"
  features {}
}

provider "google" {
  version = "~> 3.0"
  region  = var.gcp_region
}

# AWS EC2 INSTANCE
resource "aws_key_pair" "aws_key_pair" {
  key_name   = var.aws_key_pair_name
  public_key = var.aws_public_key
}

resource "aws_instance" "aws_instance" {
  ami           = var.aws_ami
  instance_type = var.aws_instance_type
  key_name      = aws_key_pair.aws_key_pair.key_name
  tags = {
    Name = "aws-ec2-instance"
  }
}

resource "aws_security_group" "aws_security_group" {
  name        = "aws-security-group"
  description = "Allow inbound traffic on port 22"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# AZURE LINUX VM
resource "azurerm_resource_group" "azure_resource_group" {
  name     = "azure-resource-group"
  location = var.azure_region
}

resource "azurerm_virtual_network" "azure_virtual_network" {
  name                = "azure-virtual-network"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.azure_resource_group.location
  resource_group_name = azurerm_resource_group.azure_resource_group.name
}

resource "azurerm_subnet" "azure_subnet" {
  name                 = "azure-subnet"
  resource_group_name = azurerm_resource_group.azure_resource_group.name
  virtual_network_name = azurerm_virtual_network.azure_virtual_network.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_network_security_group" "azure_network_security_group" {
  name                = "azure-network-security-group"
  location            = azurerm_resource_group.azure_resource_group.location
  resource_group_name = azurerm_resource_group.azure_resource_group.name
}

resource "azurerm_network_security_rule" "azure_network_security_rule" {
  name                        = "azure-network-security-rule"
  resource_group_name         = azurerm_resource_group.azure_resource_group.name
  network_security_group_name = azurerm_network_security_group.azure_network_security_group.name
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range          = "*"
  destination_port_range     = "22"
  source_address_prefix      = "*"
  destination_address_prefix = "*"
}

resource "azurerm_public_ip" "azure_public_ip" {
  name                = "azure-public-ip"
  location            = azurerm_resource_group.azure_resource_group.location
  resource_group_name = azurerm_resource_group.azure_resource_group.name
  allocation_method   = "Dynamic"
}

resource "azurerm_network_interface" "azure_network_interface" {
  name                = "azure-network-interface"
  location            = azurerm_resource_group.azure_resource_group.location
  resource_group_name = azurerm_resource_group.azure_resource_group.name

  ip_configuration {
    name                          = "azure-ip-configuration"
    subnet_id                     = azurerm_subnet.azure_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.azure_public_ip.id
  }
}

resource "azurerm_linux_virtual_machine" "azure_linux_virtual_machine" {
  name                = "azure-linux-virtual-machine"
  location            = azurerm_resource_group.azure_resource_group.location
  resource_group_name = azurerm_resource_group.azure_resource_group.name
  size                = var.azure_instance_type

  network_interface_ids = [
    azurerm_network_interface.azure_network_interface.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = var.azure_image_publisher
    offer     = var.azure_image_offer
    sku       = var.azure_image_sku
    version   = var.azure_image_version
  }
}

# GCP COMPUTE ENGINE INSTANCE
resource "google_compute_network" "gcp_network" {
  name                    = "gcp-network"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "gcp_subnetwork" {
  name          = "gcp-subnetwork"
  ip_cidr_range = "10.0.0.0/16"
  network       = google_compute_network.gcp_network.id
  region        = var.gcp_region
}

resource "google_compute_firewall" "gcp_firewall" {
  name    = "gcp-firewall"
  network = google_compute_network.gcp_network.id

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
}

resource "google_compute_instance" "gcp_instance" {
  name         = "gcp-instance"
  machine_type = var.gcp_instance_type
  zone         = "${var.gcp_region}-a"

  boot_disk {
    initialize_params {
      image = var.gcp_image
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.gcp_subnetwork.id
  }

  metadata = {
    ssh-keys = "username:${file("~/.ssh/id_rsa.pub")}"
  }
}