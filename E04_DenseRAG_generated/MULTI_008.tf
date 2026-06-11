# Configure the AWS Provider
provider "aws" {
  region = var.aws_region
}

# Configure the Azure Provider
provider "azurerm" {
  version = ">= 2.34.0"
  features {}
}

# Configure the GCP Provider
provider "google" {
  project = var.gcp_project
  region  = var.gcp_region
}

# Variables
variable "aws_region" {
  default = "us-west-2"
}

variable "aws_instance_type" {
  default = "t2.micro"
}

variable "aws_iam_instance_profile" {
  default = "EC2Admin"
}

variable "azure_location" {
  default = "West US"
}

variable "azure_vm_size" {
  default = "Standard_DS2_v2"
}

variable "gcp_project" {
  default = "my-gcp-project"
}

variable "gcp_region" {
  default = "us-central1"
}

variable "gcp_machine_type" {
  default = "e2-medium"
}

# Create AWS EC2 instance
resource "aws_instance" "aws_ec2" {
  ami           = "ami-0c94855ba95c71c99"
  instance_type = var.aws_instance_type
  iam_instance_profile = var.aws_iam_instance_profile
  tags = {
    Name = "aws-ec2-instance"
  }
}

# Create Azure Linux VM
resource "azurerm_virtual_machine" "azure_vm" {
  name                  = "azure-linux-vm"
  location              = var.azure_location
  resource_group_name = var.azure_resource_group
  vm_size               = var.azure_vm_size

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }

  os_profile {
    computer_name  = "azure-linux-vm"
    admin_username = "adminuser"
    admin_password = var.azure_admin_password
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }

  network_interface_ids = [azurerm_network_interface.azure_nic.id]
}

resource "azurerm_network_interface" "azure_nic" {
  name                = "azure-nic"
  location            = var.azure_location
  resource_group_name = var.azure_resource_group

  ip_configuration {
    name                          = "azure-nic-config"
    subnet_id                     = var.azure_subnet_id
    private_ip_address_allocation = "Dynamic"
  }
}

variable "azure_resource_group" {
  default = "my-azure-rg"
}

variable "azure_admin_password" {
  sensitive = true
}

variable "azure_subnet_id" {
  default = "/subscriptions/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx/resourceGroups/my-azure-rg/providers/Microsoft.Network/virtualNetworks/my-azure-vnet/subnets/my-azure-subnet"
}

# Create GCP Compute Engine instance
resource "google_compute_instance" "gcp_instance" {
  name         = "gcp-instance"
  machine_type = var.gcp_machine_type
  zone         = "${var.gcp_region}-a"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-9"
    }
  }

  network_interface {
    network = "default"
  }
}