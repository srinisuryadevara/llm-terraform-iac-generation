terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=2.86.0"
    }
  }
}

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

resource "azurerm_resource_group" "terraform_resource_group" {
  name     = var.resource_group_name
  location = var.azure_default_location
}

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

resource "azurerm_public_ip" "mypublicip" {
  name                = "myPublicIP"
  resource_group_name = azurerm_resource_group.terraform_resource_group.name
  location            = var.azure_default_location
  allocation_method   = "Dynamic"
}

resource "azurerm_network_interface" "myvmnic" {
  name                = "myVMNic"
  resource_group_name = azurerm_resource_group.terraform_resource_group.name
  location            = var.azure_default_location

  ip_configuration {
    name                          = "myNicConfiguration"
    subnet_id                     = azurerm_subnet.myterraformsubnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.mypublicip.id
  }
}

resource "azurerm_subnet" "myterraformsubnet" {
  name                 = "mySubnet"
  resource_group_name = azurerm_resource_group.terraform_resource_group.name
  virtual_network_name = azurerm_virtual_network.myterraformvnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_virtual_network" "myterraformvnet" {
  name                = "myVnet"
  address_space       = ["10.0.0.0/16"]
  location            = var.azure_default_location
  resource_group_name = azurerm_resource_group.terraform_resource_group.name
}

resource "azurerm_linux_virtual_machine" "mylinuxvm" {
  name                = var.vm_name
  computer_name       = var.vm_name
  resource_group_name = azurerm_resource_group.terraform_resource_group.name
  location            = var.azure_default_location
  size                = "Standard_DS1_v2"
  admin_username      = "azureuser"
  network_interface_ids = [ azurerm_network_interface.myvmnic.id ]
  admin_ssh_key {
    username   = "azureuser"
    public_key = var.ssh_public_key
  }
  os_disk {
    name = "osdisk"
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