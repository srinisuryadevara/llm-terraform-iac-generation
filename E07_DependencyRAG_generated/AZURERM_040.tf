terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=2.86.0"
    }
  }
}

provider "azurerm" {
  features {}
}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "app_name" {
  type = string
}

variable "subnet_id" {
  type = string
}

variable "public_ip_address_id" {
  type = string
}

resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_public_ip" "pip" {
  name                = "${var.app_name}-pip"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  allocation_method   = "Dynamic"
}

resource "azurerm_virtual_network" "vnet" {
  name                = "${var.app_name}-vnet"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "subnet" {
  name                 = "${var.app_name}-subnet"
  resource_group_name = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_application_gateway" "appgw" {
  name                = "${var.app_name}-appgw"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  sku {
    name     = "Standard_Small"
    tier     = "Standard"
    capacity = 2
  }

  gateway_ip_configuration {
    name      = "${var.app_name}-ip-config"
    subnet_id = azurerm_subnet.subnet.id
  }

  frontend_port {
    name = "${var.app_name}-frontend-port"
    port = 80
  }

  frontend_ip_configuration {
    name                 = "${var.app_name}-frontend-ip-config"
    public_ip_address_id = azurerm_public_ip.pip.id
  }

  backend_address_pool {
    name = "${var.app_name}-backend-pool"
  }

  backend_http_settings {
    name                  = "${var.app_name}-http-settings"
    cookie_based_affinity = "Disabled"
    path                  = "/path1/"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 60
  }

  http_listener {
    name                           = "${var.app_name}-http-listener"
    frontend_ip_configuration_name = azurerm_application_gateway.appgw.frontend_ip_configuration[0].name
    frontend_port_name             = azurerm_application_gateway.appgw.frontend_port[0].name
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = "${var.app_name}-routing-rule"
    rule_type                  = "Basic"
    http_listener_name         = azurerm_application_gateway.appgw.http_listener[0].name
    backend_address_pool_name  = azurerm_application_gateway.appgw.backend_address_pool[0].name
    backend_http_settings_name = azurerm_application_gateway.appgw.backend_http_settings[0].name
  }

  web_application_firewall_configuration {
    enabled                  = true
    firewall_mode            = "Prevention"
    rule_set_version         = "3.1"
    file_upload_limit_mb     = 100
    request_body_limit_kb    = 128
  }
}

resource "azurerm_web_application_firewall_policy" "waf_policy" {
  name                = "${var.app_name}-waf-policy"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  mode                = "Prevention"

  policy_settings {
    enabled                     = true
    file_upload_limit_mb        = 100
    request_body_limit_kb       = 128
  }

  managed_rules {
    managed_rule_set {
      type    = "OWASP"
      version = "3.1"
    }
  }
}

resource "azurerm_application_gateway_web_application_firewall_policy_association" "waf_association" {
  application_gateway_id = azurerm_application_gateway.appgw.id
  web_application_firewall_policy_id = azurerm_web_application_firewall_policy.waf_policy.id
}