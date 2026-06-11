variable "resource_group_name" {
  type        = string
  description = "The name of the resource group"
}

variable "location" {
  type        = string
  description = "The location of the resource group"
}

variable "virtual_network_name" {
  type        = string
  description = "The name of the virtual network"
}

variable "subnet_name" {
  type        = string
  description = "The name of the subnet"
}

variable "private_dns_zone_name" {
  type        = string
  description = "The name of the private DNS zone"
}

variable "private_endpoint_name" {
  type        = string
  description = "The name of the private endpoint"
}

variable "private_link_service_name" {
  type        = string
  description = "The name of the private link service"
}

resource "azurerm_resource_group" "example" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_virtual_network" "example" {
  name                = var.virtual_network_name
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
}

resource "azurerm_subnet" "example" {
  name                 = var.subnet_name
  resource_group_name = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.example.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_private_dns_zone" "example" {
  name                = var.private_dns_zone_name
  resource_group_name = azurerm_resource_group.example.name
}

resource "azurerm_private_link_service" "example" {
  name                = var.private_link_service_name
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  load_balancer_frontend_ip_configurations {
    name                          = "example-frontend"
    private_ip_address            = "10.0.1.4"
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = azurerm_subnet.example.id
  }
}

resource "azurerm_private_endpoint" "example" {
  name                = var.private_endpoint_name
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  subnet_id           = azurerm_subnet.example.id
  private_service_connection {
    name                           = "example-connection"
    private_connection_resource_id = azurerm_private_link_service.example.id
    subresource_names              = ["example-subresource"]
    is_manual_connection           = false
  }
  private_dns_zone_group {
    name                 = "example-dns-zone-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.example.id]
  }
}