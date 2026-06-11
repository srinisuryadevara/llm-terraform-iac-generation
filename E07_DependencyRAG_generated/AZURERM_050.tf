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

variable "primary_web_application" {
  type = object({
    default_site_hostname = string
  })
}

variable "secondary_web_application" {
  type = object({
    default_site_hostname = string
  })
}

resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_public_ip" "pip" {
  name                = "pip-${var.app_name}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  allocation_method   = "Dynamic"
}

resource "azurerm_application_gateway" "network" {
  name                = "appgw-${var.app_name}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  sku {
    name     = "Standard_Small"
    tier     = "Standard"
    capacity = 2
  }

  gateway_ip_configuration {
    name      = "my-gateway-ip-configuration"
    subnet_id = azurerm_subnet.subnet.id
  }

  frontend_port {
    name = "http"
    port = 80
  }

  frontend_ip_configuration {
    name                 = "frontendip"
    public_ip_address_id = azurerm_public_ip.pip.id
  }

  backend_address_pool {
    name = "backend"
  }

  backend_http_settings {
    name                  = "httpsetting"
    cookie_based_affinity = "Disabled"
    path                  = "/path1/"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 60
  }

  http_listener {
    name                           = "listener"
    frontend_ip_configuration_name = "frontendip"
    frontend_port_name             = "http"
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = "routingrule"
    rule_type                  = "Basic"
    http_listener_name         = "listener"
    backend_address_pool_name  = "backend"
    backend_http_settings_name = "httpsetting"
  }

  waf_configuration {
    enabled                  = true
    firewall_mode            = "Prevention"
    rule_set_version         = "3.2"
    file_upload_limit_mb     = 100
    max_request_body_size_kb = 128
  }
}

resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-${var.app_name}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "subnet" {
  name                 = "subnet-${var.app_name}"
  resource_group_name = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_service_plan" "appserviceplan" {
  name                = "asp-${var.app_name}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  os_type             = "Windows"
  sku_name            = "S1"
}

resource "azurerm_windows_web_app" "primary_web_app" {
  name                  = "primary-${var.app_name}"
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  service_plan_id       = azurerm_service_plan.appserviceplan.id
  https_only            = true
  site_config { 
    minimum_tls_version = "1.2"
    application_stack {
        current_stack         = "dotnet"
        dotnet_version        = "v6.0"
    }
  }
}

resource "azurerm_windows_web_app" "secondary_web_app" {
  name                  = "secondary-${var.app_name}"
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  service_plan_id       = azurerm_service_plan.appserviceplan.id
  https_only            = true
  site_config { 
    minimum_tls_version = "1.2"
    application_stack {
        current_stack         = "dotnet"
        dotnet_version        = "v6.0"
    }
  }
}

resource "azurerm_application_gateway_backend_address_pool" "primary_pool" {
  name            = "primary-pool"
  application_gateway_id = azurerm_application_gateway.network.id
}

resource "azurerm_application_gateway_backend_address_pool" "secondary_pool" {
  name            = "secondary-pool"
  application_gateway_id = azurerm_application_gateway.network.id
}

resource "azurerm_application_gateway_backend_http_settings" "primary_settings" {
  name                  = "primary-settings"
  application_gateway_id = azurerm_application_gateway.network.id
  cookie_based_affinity = "Disabled"
  path                  = "/path1/"
  port                  = 80
  protocol              = "Http"
  request_timeout       = 60
}

resource "azurerm_application_gateway_backend_http_settings" "secondary_settings" {
  name                  = "secondary-settings"
  application_gateway_id = azurerm_application_gateway.network.id
  cookie_based_affinity = "Disabled"
  path                  = "/path1/"
  port                  = 80
  protocol              = "Http"
  request_timeout       = 60
}

resource "azurerm_application_gateway_url_path_map" "primary_map" {
  name                               = "primary-map"
  application_gateway_id             = azurerm_application_gateway.network.id
  default_backend_address_pool_name  = azurerm_application_gateway_backend_address_pool.primary_pool.name
  default_backend_http_settings_name = azurerm_application_gateway_backend_http_settings.primary_settings.name

  path_rule {
    name                       = "primary-rule"
    paths                      = ["/primary/*"]
    backend_address_pool_name  = azurerm_application_gateway_backend_address_pool.primary_pool.name
    backend_http_settings_name = azurerm_application_gateway_backend_http_settings.primary_settings.name
  }
}

resource "azurerm_application_gateway_url_path_map" "secondary_map" {
  name                               = "secondary-map"
  application_gateway_id             = azurerm_application_gateway.network.id
  default_backend_address_pool_name  = azurerm_application_gateway_backend_address_pool.secondary_pool.name
  default_backend_http_settings_name = azurerm_application_gateway_backend_http_settings.secondary_settings.name

  path_rule {
    name                       = "secondary-rule"
    paths                      = ["/secondary/*"]
    backend_address_pool_name  = azurerm_application_gateway_backend_address_pool.secondary_pool.name
    backend_http_settings_name = azurerm_application_gateway_backend_http_settings.secondary_settings.name
  }
}

resource "azurerm_application_gateway_backend_address_pool_address" "primary_address" {
  name                    = "primary-address"
  backend_address_pool_id = azurerm_application_gateway_backend_address_pool.primary_pool.id
  ip_address             = azurerm_windows_web_app.primary_web_app.default_hostname
}

resource "azurerm_application_gateway_backend_address_pool_address" "secondary_address" {
  name                    = "secondary-address"
  backend_address_pool_id = azurerm_application_gateway_backend_address_pool.secondary_pool.id
  ip_address             = azurerm_windows_web_app.secondary_web_app.default_hostname
}