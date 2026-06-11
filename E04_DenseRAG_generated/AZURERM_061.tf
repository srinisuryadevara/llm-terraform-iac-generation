# Configure the Azure Provider
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=2.86.0"
    }
  }
}

# Variable declarations
variable "azure_default_location" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "vm_name" {
  type = string
}

variable "ssh_public_key" {
  type = string
  sensitive = true
}

# Create a resource group
resource "azurerm_resource_group" "terraform_resource_group" {
  name     = var.resource_group_name
  location = var.azure_default_location
}

# Create a public IP
resource "azurerm_public_ip" "terraform_public_ip" {
  name                = "AzureDemoTerraform-PIP"
  location            = var.azure_default_location
  resource_group_name = azurerm_resource_group.terraform_resource_group.name
  allocation_method   = "Dynamic"
}

# Create a network security group
resource "azurerm_network_security_group" "terraform_security_group_ssh" {
  name                = "AzureDemoTerraform-SG-SSH"
  location            = var.azure_default_location
  resource_group_name = azurerm_resource_group.terraform_resource_group.name

  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Create a network interface
resource "azurerm_network_interface" "terraform_network_interface" {
  name                = "AzureDemoTerraform-NIC"
  location            = var.azure_default_location
  resource_group_name = azurerm_resource_group.terraform_resource_group.name

  ip_configuration {
    name                          = "AzureDemoTerraform-NIC-Config"
    subnet_id                     = azurerm_subnet.terraform_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.terraform_public_ip.id
  }
}

# Create a subnet
resource "azurerm_subnet" "terraform_subnet" {
  name                 = "AzureDemoTerraform-Subnet"
  resource_group_name = azurerm_resource_group.terraform_resource_group.name
  virtual_network_name = azurerm_virtual_network.terraform_virtual_network.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Create a virtual network
resource "azurerm_virtual_network" "terraform_virtual_network" {
  name                = "AzureDemoTerraform-VNET"
  location            = var.azure_default_location
  resource_group_name = azurerm_resource_group.terraform_resource_group.name
  address_space       = ["10.0.0.0/16"]
}

# Associate the network security group with the subnet
resource "azurerm_subnet_network_security_group_association" "terraform_subnet_nsg_association" {
  subnet_id                 = azurerm_subnet.terraform_subnet.id
  network_security_group_id = azurerm_network_security_group.terraform_security_group_ssh.id
}

# Create a Linux virtual machine
resource "azurerm_linux_virtual_machine" "terraform_linux_vm" {
  name                = var.vm_name
  computer_name       = var.vm_name
  resource_group_name = azurerm_resource_group.terraform_resource_group.name
  location            = var.azure_default_location
  size                = "Standard_DS1_v2"
  admin_username      = "azureuser"
  network_interface_ids = [ azurerm_network_interface.terraform_network_interface.id ]
  admin_ssh_key {
    username   = "azureuser"
    public_key = var.ssh_public_key
  }
  os_disk {
    name = "osdisk${random_string.myrandom.id}"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
  source_image_reference {
    publisher = "RedHat"
    offer     = "RHEL"
    sku       = "83-gen2"
    version   = "latest"
  }
}

# Generate a random string
resource "random_string" "myrandom" {
  length = 8
  special = false
  upper   = false
}