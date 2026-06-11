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
  default = "aws-key"
}

variable "aws_public_key" {
  default = file("~/.ssh/id_rsa.pub")
}

variable "azure_subscription_id" {
  default = "your_subscription_id"
}

variable "azure_client_id" {
  default = "your_client_id"
}

variable "azure_client_secret" {
  default = "your_client_secret"
}

variable "azure_tenant_id" {
  default = "your_tenant_id"
}

variable "azure_location" {
  default = "West US"
}

variable "azure_vm_size" {
  default = "Standard_DS2_v2"
}

variable "azure_image_publisher" {
  default = "Canonical"
}

variable "azure_image_offer" {
  default = "UbuntuServer"
}

variable "azure_image_sku" {
  default = "16.04-LTS"
}

variable "gcp_project" {
  default = "your_project_id"
}

variable "gcp_region" {
  default = "us-central1"
}

variable "gcp_zone" {
  default = "us-central1-a"
}

variable "gcp_instance_type" {
  default = "f1-micro"
}

variable "gcp_image" {
  default = "debian-cloud/debian-9"
}

# PROVIDERS
provider "aws" {
  region = var.aws_region
}

provider "azurerm" {
  version = "2.34.0"
  subscription_id = var.azure_subscription_id
  client_id      = var.azure_client_id
  client_secret = var.azure_client_secret
  tenant_id      = var.azure_tenant_id
  features {}
}

provider "google" {
  project = var.gcp_project
  region  = var.gcp_region
}

# AWS RESOURCES
resource "aws_key_pair" "aws-key" {
  key_name   = var.aws_key_pair_name
  public_key = var.aws_public_key
}

resource "aws_instance" "aws-ec2" {
  ami           = var.aws_ami
  instance_type = var.aws_instance_type
  key_name               = aws_key_pair.aws-key.key_name
  vpc_security_group_ids = [aws_security_group.aws-sg.id]
}

resource "aws_security_group" "aws-sg" {
  name        = "aws-sg"
  description = "AWS security group"
}

# AZURE RESOURCES
resource "azurerm_resource_group" "azure-rg" {
  name     = "azure-rg"
  location = var.azure_location
}

resource "azurerm_virtual_network" "azure-vn" {
  name                = "azure-vn"
  address_space       = ["10.0.0.0/16"]
  location            = var.azure_location
  resource_group_name = azurerm_resource_group.azure-rg.name
}

resource "azurerm_subnet" "azure-sn" {
  name                 = "azure-sn"
  resource_group_name = azurerm_resource_group.azure-rg.name
  virtual_network_name = azurerm_virtual_network.azure-vn.name
  address_prefix       = "10.0.1.0/24"
}

resource "azurerm_network_security_group" "azure-nsg" {
  name                = "azure-nsg"
  location            = var.azure_location
  resource_group_name = azurerm_resource_group.azure-rg.name
}

resource "azurerm_network_interface" "azure-ni" {
  name                = "azure-ni"
  location            = var.azure_location
  resource_group_name = azurerm_resource_group.azure-rg.name

  ip_configuration {
    name                          = "azure-nic"
    subnet_id                     = azurerm_subnet.azure-sn.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_virtual_machine" "azure-vm" {
  name                  = "azure-vm"
  location              = var.azure_location
  resource_group_name = azurerm_resource_group.azure-rg.name
  vm_size               = var.azure_vm_size

  storage_image_reference {
    publisher = var.azure_image_publisher
    offer     = var.azure_image_offer
    sku       = var.azure_image_sku
    version   = "latest"
  }

  os_profile {
    computer_name  = "azure-vm"
    admin_username = "adminuser"
    admin_password = "P@ssw0rd1234!"
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }

  network_interface_ids = [azurerm_network_interface.azure-ni.id]
}

# GCP RESOURCES
data "google_compute_zones" "available" {
  region = var.gcp_region
}

resource "google_compute_address" "gcp-ip" {
  name = "gcp-vm-ip"
  region = var.gcp_region
}

resource "google_compute_instance" "gcp-vm" {
  name         = "gcp-vm"
  machine_type = var.gcp_instance_type
  zone         = data.google_compute_zones.available.names[0]

  boot_disk {
    initialize_params {
      image = var.gcp_image
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.gcp-subnet1.name
    access_config {
      nat_ip = google_compute_address.gcp-ip.address
    }
  }
}

resource "google_compute_subnetwork" "gcp-subnet1" {
  name          = "gcp-subnet1"
  ip_cidr_range = "10.0.1.0/24"
  region        = var.gcp_region
}