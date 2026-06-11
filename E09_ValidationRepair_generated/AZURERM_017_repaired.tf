provider "azurerm" {
  version = "3.34.0"
  features {}
}

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group"
}

variable "location" {
  type        = string
  description = "Location of the resource group"
}

variable "bastion_host_name" {
  type        = string
  description = "Name of the bastion host"
}

variable "public_ip_name" {
  type        = string
  description = "Name of the public IP"
}

resource "azurerm_resource_group" "example" {
  name     = var.resource_group_name
  location = var.location
  tags = {
    Environment = "example"
    ManagedBy   = "Terraform"
  }
}

resource "azurerm_virtual_network" "example" {
  name                = "example-vnet"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  address_space       = ["10.0.0.0/16"]
  tags = {
    Environment = "example"
    ManagedBy   = "Terraform"
  }
}

resource "azurerm_subnet" "example" {
  name                 = "AzureBastionSubnet"
  resource_group_name = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.example.name
  address_prefixes     = ["10.0.0.0/24"]
  tags = {
    Environment = "example"
    ManagedBy   = "Terraform"
  }
}

resource "azurerm_public_ip" "example" {
  name                = var.public_ip_name
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  allocation_method   = "Static"
  sku                 = "Standard"
  tags = {
    Environment = "example"
    ManagedBy   = "Terraform"
  }
}

resource "azurerm_bastion_host" "example" {
  name                = var.bastion_host_name
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  sku                 = "Standard"
  ip_configuration {
    name                 = "example"
    subnet_id            = azurerm_subnet.example.id
    public_ip_address_id = azurerm_public_ip.example.id
  }
  tags = {
    Environment = "example"
    ManagedBy   = "Terraform"
  }
}

output "resource_group_id" {
  value       = azurerm_resource_group.example.id
  description = "ID of the resource group"
}

output "virtual_network_id" {
  value       = azurerm_virtual_network.example.id
  description = "ID of the virtual network"
}

output "subnet_id" {
  value       = azurerm_subnet.example.id
  description = "ID of the subnet"
}

output "public_ip_id" {
  value       = azurerm_public_ip.example.id
  description = "ID of the public IP"
}

output "public_ip_address" {
  value       = azurerm_public_ip.example.ip_address
  description = "IP address of the public IP"
}

output "bastion_host_id" {
  value       = azurerm_bastion_host.example.id
  description = "ID of the bastion host"
}