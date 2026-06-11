provider "azurerm" {
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
    environment = "example"
  }
}

resource "azurerm_public_ip" "example" {
  name                = var.public_ip_name
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  allocation_method   = "Static"
  sku                 = "Standard"
  tags = {
    environment = "example"
  }
}

resource "azurerm_bastion_host" "example" {
  name                = var.bastion_host_name
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  sku                 = "Standard"
  tags = {
    environment = "example"
  }

  ip_configuration {
    name                 = "example"
    subnet_id            = azurerm_subnet.example.id
    public_ip_address_id = azurerm_public_ip.example.id
  }

  depends_on = [azurerm_subnet.example]
}

resource "azurerm_virtual_network" "example" {
  name                = "example-vnet"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  address_space       = ["10.0.0.0/16"]
  tags = {
    environment = "example"
  }
}

resource "azurerm_subnet" "example" {
  name                 = "AzureBastionSubnet"
  resource_group_name = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.example.name
  address_prefixes     = ["10.0.1.0/24"]
  tags = {
    environment = "example"
  }
}

output "resource_group_id" {
  value = azurerm_resource_group.example.id
}

output "public_ip_address" {
  value = azurerm_public_ip.example.ip_address
}

output "bastion_host_id" {
  value = azurerm_bastion_host.example.id
}

output "virtual_network_id" {
  value = azurerm_virtual_network.example.id
}

output "subnet_id" {
  value = azurerm_subnet.example.id
}