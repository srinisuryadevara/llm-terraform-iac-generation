# Configure the Azure Provider
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=2.86.0"
    }
  }
}

# Define variables
variable "azure_default_location" {
  type        = string
  default     = "West US"
}

variable "resource_group_name" {
  type        = string
  default     = "myresourcegroup"
}

variable "vm_name" {
  type        = string
  default     = "mylinuxvm"
}

variable "admin_username" {
  type        = string
  sensitive   = true
}

variable "admin_ssh_key" {
  type        = string
  sensitive   = true
}

# Create a resource group
resource "azurerm_resource_group" "example" {
  name     = var.resource_group_name
  location = var.azure_default_location
}

# Create a virtual network
resource "azurerm_virtual_network" "example" {
  name                = "example-virtual-network"
  address_space       = ["10.0.0.0/16"]
  location            = var.azure_default_location
  resource_group_name = azurerm_resource_group.example.name
}

# Create a subnet
resource "azurerm_subnet" "example" {
  name                 = "example-subnet"
  resource_group_name = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.example.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Create a public IP
resource "azurerm_public_ip" "example" {
  name                = "example-public-ip"
  location            = var.azure_default_location
  resource_group_name = azurerm_resource_group.example.name
  allocation_method   = "Dynamic"
}

# Create a network security group
resource "azurerm_network_security_group" "example" {
  name                = "example-network-security-group"
  location            = var.azure_default_location
  resource_group_name = azurerm_resource_group.example.name

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
resource "azurerm_network_interface" "example" {
  name                = "example-network-interface"
  location            = var.azure_default_location
  resource_group_name = azurerm_resource_group.example.name

  ip_configuration {
    name                          = "example-ip-configuration"
    subnet_id                     = azurerm_subnet.example.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.example.id
  }
}

# Create a Linux virtual machine
resource "azurerm_linux_virtual_machine" "example" {
  name                = var.vm_name
  computer_name       = var.vm_name
  resource_group_name = azurerm_resource_group.example.name
  location            = var.azure_default_location
  size                = "Standard_DS1_v2"
  admin_username      = var.admin_username
  network_interface_ids = [ azurerm_network_interface.example.id ]
  admin_ssh_key {
    username   = var.admin_username
    public_key = file("${path.module}/${var.admin_ssh_key}")
  }
  os_disk {
    name = "osdisk${random_string.example.id}"
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
resource "random_string" "example" {
  length = 8
  special = false
  upper   = false
}