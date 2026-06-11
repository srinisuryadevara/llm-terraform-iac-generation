provider "azurerm" {
  version = "3.34.0"
  features {}
}

variable "region" {
  type        = string
  description = "Azure region"
}

variable "project" {
  type        = string
  description = "Project name"
}

variable "environment" {
  type        = string
  description = "Environment name"
}

variable "bastion_host" {
  type        = string
  description = "Bastion host name"
}

variable "public_ip_name" {
  type        = string
  description = "Public IP name"
}

variable "ssh_source_cidr" {
  type        = string
  description = "SSH source CIDR"
}

resource "azurerm_resource_group" "example" {
  name     = "${var.project}-${var.environment}-rg"
  location = var.region
  tags = {
    environment = var.environment
    project     = var.project
  }
}

resource "azurerm_public_ip" "example" {
  name                = var.public_ip_name
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags = {
    environment = var.environment
    project     = var.project
  }
}

resource "azurerm_bastion_host" "example" {
  name                = var.bastion_host
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  sku                 = "Standard"
  tags = {
    environment = var.environment
    project     = var.project
  }

  ip_configuration {
    name                 = "example"
    subnet_id            = azurerm_subnet.example.id
    public_ip_address_id = azurerm_public_ip.example.id
  }

  tls_key {
    key                = tls_private_key.example.private_key_pem
    certificate        = tls_self_signed_cert.example.cert_pem
    min_tls_version    = "TLS1_2"
  }
}

resource "azurerm_subnet" "example" {
  name                 = "AzureBastionSubnet"
  resource_group_name = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.example.name
}

resource "azurerm_virtual_network" "example" {
  name                = "${var.project}-${var.environment}-vnet"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  address_space       = ["10.0.0.0/16"]
  tags = {
    environment = var.environment
    project     = var.project
  }
}

resource "tls_private_key" "example" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_self_signed_cert" "example" {
  key_algorithm   = "RSA"
  private_key_pem = tls_private_key.example.private_key_pem
  subject {
    common_name = "example.com"
  }
  validity_period_hours = 8760
  is_ca_certificate     = true
  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]
}

resource "azurerm_network_security_group" "example" {
  name                = "${var.project}-${var.environment}-nsg"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  tags = {
    environment = var.environment
    project     = var.project
  }
}

resource "azurerm_network_security_rule" "example" {
  name                        = "SSH"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range          = "*"
  destination_port_range     = "22"
  source_address_prefix      = var.ssh_source_cidr
  destination_address_prefix = azurerm_subnet.example.address_prefix
  resource_group_name        = azurerm_resource_group.example.name
  network_security_group_name = azurerm_network_security_group.example.name
}

resource "azurerm_subnet_network_security_group_association" "example" {
  subnet_id                 = azurerm_subnet.example.id
  network_security_group_id = azurerm_network_security_group.example.id
}