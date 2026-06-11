variable "azure_location" {
  type = string
}

variable "bastion_host_name" {
  type = string
}

variable "resource_group_name" {
  type = string
}

resource "azurerm_public_ip" "bastion_pip" {
  name                = "${var.bastion_host_name}-pip"
  location            = var.azure_location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"

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
    subnet_id            = var.subnet_id
    public_ip_address_id = azurerm_public_ip.bastion_pip.id
  }

  tags = {
    environment = "Bastion Host"
  }
}

variable "subnet_id" {
  type = string
}