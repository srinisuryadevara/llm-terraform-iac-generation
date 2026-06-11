provider "aws" {
  region = var.aws_region
}

provider "azurerm" {
  features {}
  subscription_id = var.azurerm_subscription_id
  client_id       = var.azurerm_client_id
  client_secret   = var.azurerm_client_secret
  tenant_id       = var.azurerm_tenant_id
}

provider "google" {
  project = var.gcp_project
  region  = var.gcp_region
}

resource "aws_instance" "example" {
  ami           = var.aws_ami
  instance_type = var.aws_instance_type
  tags = {
    Name = "aws-ec2-instance"
  }
}

resource "azurerm_virtual_machine" "example" {
  name                  = "azurerm-linux-vm"
  location              = var.azurerm_location
  resource_group_name    = var.azurerm_resource_group_name
  vm_size               = var.azurerm_vm_size
  delete_os_disk_on_termination = true

  storage_image_reference {
    publisher = var.azurerm_publisher
    offer     = var.azurerm_offer
    sku       = var.azurerm_sku
    version   = var.azurerm_version
  }

  os_profile {
    computer_name  = "azurerm-linux-vm"
    admin_username = var.azurerm_admin_username
    admin_password = var.azurerm_admin_password
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }
}

resource "google_compute_instance" "example" {
  name         = "gcp-compute-engine"
  machine_type = var.gcp_machine_type
  zone         = var.gcp_zone

  boot_disk {
    initialize_params {
      image = var.gcp_image
    }
  }

  network_interface {
    network = var.gcp_network
  }
}