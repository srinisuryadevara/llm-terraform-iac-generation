terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0.0"
    }
  }
  required_version = ">= 0.14.9"
}

provider "azurerm" {
  features {}
}

variable "azure_location" {
  type        = string
  default     = "East Asia"
}

variable "resource_group_name" {
  type        = string
  default     = "appgw-terraform-rg"
}

variable "virtual_network_name" {
  type        = string
  default     = "appgw-terraform-vnet"
}

variable "subnet_name" {
  type        = string
  default     = "appgw-terraform-subnet"
}

variable "public_ip_name" {
  type        = string
  default     = "appgw-terraform-pip"
}

variable "application_gateway_name" {
  type        = string
  default     = "appgw-terraform"
}

resource "azurerm_resource_group" "example" {
  name     = var.resource_group_name
  location = var.azure_location
}

resource "azurerm_virtual_network" "example-vnet" {
  name                = var.virtual_network_name
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "example-subnet" {
  name                 = var.subnet_name
  virtual_network_name = azurerm_virtual_network.example-vnet.name
  resource_group_name  = azurerm_resource_group.example.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_public_ip" "example-pip" {
  name                = var.public_ip_name
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  allocation_method   = "Dynamic"
}

resource "azurerm_application_gateway" "example-appgw" {
  name                = var.application_gateway_name
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location

  sku {
    name = "Standard_Small"
    tier = "Standard"
  }

  gateway_ip_configuration {
    name      = "appgw-ip-config"
    subnet_id = azurerm_subnet.example-subnet.id
  }

  frontend_ip_configuration {
    name                 = "appgw-frontend-ip-config"
    public_ip_address_id = azurerm_public_ip.example-pip.id
  }

  frontend_port {
    name = "appgw-frontend-port"
    port = 80
  }

  backend_address_pool {
    name = "appgw-backend-pool"
  }

  backend_http_settings {
    name                  = "appgw-backend-http-settings"
    cookie_based_affinity = "Disabled"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 60
  }

  http_listener {
    name                           = "appgw-http-listener"
    frontend_ip_configuration_name = "appgw-frontend-ip-config"
    frontend_port_name             = "appgw-frontend-port"
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = "appgw-routing-rule"
    rule_type                  = "Basic"
    http_listener_name         = "appgw-http-listener"
    backend_address_pool_name  = "appgw-backend-pool"
    backend_http_settings_name = "appgw-backend-http-settings"
  }
}