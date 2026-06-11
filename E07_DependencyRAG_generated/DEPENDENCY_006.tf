terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "=2.71.0"
    }
  }
}

provider "azurerm" {
  features {}
}

variable "azure_default_location" {
  type = string
}

resource "azurerm_resource_group" "example" {
  name     = "terraform-resourcegroup"
  location = var.azure_default_location
}

resource "azurerm_virtual_network" "example-vnet" {
  name                = "example-vnet"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "example-subnet" {
  name                 = "example-subnet"
  virtual_network_name = azurerm_virtual_network.example-vnet.name
  resource_group_name  = azurerm_resource_group.example.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_private_endpoint" "example" {
  name                = "example-private-endpoint"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  subnet_id           = azurerm_subnet.example-subnet.id

  private_service_connection {
    name                           = "example-private-service-connection"
    private_connection_resource_id = azurerm_private_link_service.example.id
    subresource_names              = ["example-subresource"]
    is_manual_connection           = false
  }
}

resource "azurerm_private_link_service" "example" {
  name                = "example-private-link-service"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  load_balancer_frontend_ip_configuration_ids = [azurerm_lb.example.frontend_ip_configuration.0.id]
}

resource "azurerm_lb" "example" {
  name                = "example-load-balancer"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  sku                 = "Standard"

  frontend_ip_configuration {
    name                 = "example-frontend-ip-configuration"
    subnet_id            = azurerm_subnet.example-subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}