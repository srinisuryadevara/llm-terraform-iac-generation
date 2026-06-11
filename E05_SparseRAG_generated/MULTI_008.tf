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

variable "aws_key_pair_public_key" {
  default = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC8te8ZV9X6H..."
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
  default = "f1-micro"
}

variable "gcp_image" {
  default = "debian-cloud/debian-9"
}

variable "gcp_key_pair_name" {
  default = "gcp-key-pair"
}

variable "gcp_key_pair_public_key" {
  default = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC8te8ZV9X6H..."
}

# PROVIDERS
provider "aws" {
  region = var.aws_region
}

provider "azurerm" {
  version = "2.34.0"
  features {}
}

provider "google" {
  project = "your-project-id"
  region  = var.gcp_region
}

# AWS RESOURCES
resource "aws_key_pair" "aws_key_pair" {
  key_name   = var.aws_key_pair_name
  public_key = var.aws_key_pair_public_key
}

resource "aws_instance" "aws_instance" {
  ami           = var.aws_ami
  instance_type = var.aws_instance_type
  key_name      = aws_key_pair.aws_key_pair.key_name
}

# AZURE RESOURCES
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
  address_prefix       = "10.0.1.0/24"
}

resource "azurerm_network_interface" "azure_network_interface" {
  name                = "azure-network-interface"
  location            = azurerm_resource_group.azure_resource_group.location
  resource_group_name = azurerm_resource_group.azure_resource_group.name

  ip_configuration {
    name                          = "azure-ip-configuration"
    subnet_id                     = azurerm_subnet.azure_subnet.id
    private_ip_address_allocation = "Dynamic"
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

# GCP RESOURCES
resource "google_compute_address" "gcp_address" {
  name = "gcp-address"
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
    subnetwork = google_compute_subnetwork.gcp_subnetwork.name
    access_config {
      nat_ip = google_compute_address.gcp_address.address
    }
  }
}

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