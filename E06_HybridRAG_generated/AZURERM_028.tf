variable "azure_location" {
  type        = string
  description = "The location of the Azure resources"
}

variable "bastion_host_name" {
  type        = string
  description = "The name of the Azure Bastion Host"
}

variable "resource_group_name" {
  type        = string
  description = "The name of the resource group"
}

resource "azurerm_public_ip" "bastion_pip" {
  name                = "${var.bastion_host_name}-pip"
  location            = var.azure_location
  resource_group_name = var.resource_group_name
  allocation_method   = "Dynamic"

  tags = {
    environment = "Bastion Host"
  }
}

resource "azurerm_bastion_host" "bastion_host" {
  name                = var.bastion_host_name
  location            = var.azure_location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                 = "bastion_ip_config"
    subnet_id            = var.bastion_subnet_id
    public_ip_address_id = azurerm_public_ip.bastion_pip.id
  }

  tags = {
    environment = "Bastion Host"
  }
}

variable "bastion_subnet_id" {
  type        = string
  description = "The ID of the subnet for the Bastion Host"
}