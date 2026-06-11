provider "azurerm" {
  features {}
}

variable "subscription_id" {
  type        = string
  sensitive   = true
}

variable "client_id" {
  type        = string
  sensitive   = true
}

variable "client_secret" {
  type        = string
  sensitive   = true
}

variable "tenant_id" {
  type        = string
  sensitive   = true
}

provider "azurerm" {
  alias                   = "main"
  subscription_id         = var.subscription_id
  client_id               = var.client_id
  client_secret           = var.client_secret
  tenant_id               = var.tenant_id
  features {}
}

resource "azurerm_resource_group" "example" {
  provider = azurerm.main
  name     = "example-resource-group"
  location = "East US"
}

resource "azurerm_network_security_group" "example" {
  provider = azurerm.main
  name                = "example-nsg"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
}

resource "azurerm_network_security_rule" "deny_all" {
  provider                     = azurerm.main
  name                         = "deny-all"
  priority                     = 100
  direction                     = "Inbound"
  access                       = "Deny"
  protocol                     = "*"
  source_port_range          = "*"
  destination_port_range     = "*"
  source_address_prefix      = "*"
  destination_address_prefix = "*"
  resource_group_name         = azurerm_resource_group.example.name
  network_security_group_name = azurerm_network_security_group.example.name
}

resource "azurerm_network_security_rule" "allow_443" {
  provider                     = azurerm.main
  name                         = "allow-443"
  priority                     = 101
  direction                     = "Inbound"
  access                       = "Allow"
  protocol                     = "Tcp"
  source_port_range          = "*"
  destination_port_range     = "443"
  source_address_prefix      = "*"
  destination_address_prefix = "*"
  resource_group_name         = azurerm_resource_group.example.name
  network_security_group_name = azurerm_network_security_group.example.name
}