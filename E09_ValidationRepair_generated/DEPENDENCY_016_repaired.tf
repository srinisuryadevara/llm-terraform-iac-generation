provider "azurerm" {
  features {}
}

variable "location" {
  type        = string
  default     = "West US"
}

variable "resource_group_name" {
  type        = string
  default     = "example-resource-group"
}

variable "virtual_network_name" {
  type        = string
  default     = "example-virtual-network"
}

variable "subnet_name" {
  type        = string
  default     = "example-subnet"
}

variable "network_interface_name" {
  type        = string
  default     = "example-network-interface"
}

variable "virtual_machine_name" {
  type        = string
  default     = "example-virtual-machine"
}

variable "admin_username" {
  type        = string
  sensitive   = true
}

variable "admin_password" {
  type        = string
  sensitive   = true
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
  name                = var.virtual_network_name
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  address_space       = ["10.0.0.0/16"]
  tags = {
    Environment = "example"
    ManagedBy   = "Terraform"
  }
}

resource "azurerm_subnet" "example" {
  name                 = var.subnet_name
  resource_group_name = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.example.name
  address_prefixes     = ["10.0.1.0/24"]
  tags = {
    Environment = "example"
    ManagedBy   = "Terraform"
  }
}

resource "azurerm_network_interface" "example" {
  name                = var.network_interface_name
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location

  ip_configuration {
    name                          = "example-ip-configuration"
    subnet_id                     = azurerm_subnet.example.id
    private_ip_address_allocation = "Dynamic"
  }
  tags = {
    Environment = "example"
    ManagedBy   = "Terraform"
  }
}

resource "azurerm_linux_virtual_machine" "example" {
  name                = var.virtual_machine_name
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  size                = "Standard_DS2_v2"

  admin_username = var.admin_username
  admin_password = var.admin_password

  network_interface_ids = [
    azurerm_network_interface.example.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }
  tags = {
    Environment = "example"
    ManagedBy   = "Terraform"
  }
}

output "resource_group_id" {
  value = azurerm_resource_group.example.id
}

output "virtual_network_id" {
  value = azurerm_virtual_network.example.id
}

output "subnet_id" {
  value = azurerm_subnet.example.id
}

output "network_interface_id" {
  value = azurerm_network_interface.example.id
}

output "virtual_machine_id" {
  value = azurerm_linux_virtual_machine.example.id
}

output "virtual_machine_private_ip" {
  value = azurerm_network_interface.example.ip_configuration[0].private_ip_address
}