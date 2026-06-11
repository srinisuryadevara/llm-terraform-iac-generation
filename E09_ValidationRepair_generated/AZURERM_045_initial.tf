provider "azurerm" {
  version = "3.34.0"
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

variable "resource_group_name" {
  type        = string
}

variable "location" {
  type        = string
}

variable "vmss_name" {
  type        = string
}

variable "admin_username" {
  type        = string
  sensitive   = true
}

variable "admin_password" {
  type        = string
  sensitive   = true
}

provider "azurerm" {
  alias                   = "primary"
  subscription_id         = var.subscription_id
  client_id               = var.client_id
  client_secret           = var.client_secret
  tenant_id               = var.tenant_id
  features {}
}

resource "azurerm_resource_group" "example" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_virtual_network" "example" {
  name                = "example-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
}

resource "azurerm_subnet" "example" {
  name                 = "example-subnet"
  resource_group_name = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.example.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_public_ip" "example" {
  name                = "example-publicip"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  allocation_method   = "Dynamic"
}

resource "azurerm_lb" "example" {
  name                = "example-lb"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name

  frontend_ip_configuration {
    name                 = "example-frontendip"
    public_ip_address_id = azurerm_public_ip.example.id
  }
}

resource "azurerm_lb_backend_address_pool" "example" {
  loadbalancer_id = azurerm_lb.example.id
  name            = "example-backendpool"
}

resource "azurerm_lb_rule" "example" {
  loadbalancer_id                = azurerm_lb.example.id
  name                            = "example-lbrule"
  protocol                        = "Tcp"
  frontend_port                   = 80
  backend_port                    = 80
  backend_address_pool_id         = azurerm_lb_backend_address_pool.example.id
  frontend_ip_configuration_name  = "example-frontendip"
  probe_id                       = azurerm_lb_probe.example.id
}

resource "azurerm_lb_probe" "example" {
  loadbalancer_id = azurerm_lb.example.id
  name            = "example-lbprobe"
  protocol        = "Http"
  request_path    = "/"
  port            = 80
}

resource "azurerm_virtual_machine_scale_set" "example" {
  name                = var.vmss_name
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name

  upgrade_policy_mode = "Rolling"

  sku {
    name     = "Standard_DS2_v2"
    tier     = "Standard"
    capacity = 2
  }

  os_profile {
    computer_name_prefix = "example"
    admin_username       = var.admin_username
    admin_password       = var.admin_password
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }

  network_profile {
    name    = "example-networkprofile"
    primary = true

    ip_configuration {
      name                                   = "example-ipconfig"
      primary                                = true
      subnet_id                              = azurerm_subnet.example.id
      load_balancer_backend_address_pool_ids = [azurerm_lb_backend_address_pool.example.id]
    }
  }
}

resource "azurerm_monitor_autoscale_setting" "example" {
  name                = "example-autoscalesetting"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  target_resource_id  = azurerm_virtual_machine_scale_set.example.id

  profile {
    name = "example-profile"

    capacity {
      default = 2
      minimum = 2
      maximum = 10
    }

    rule {
      name        = "example-rule"
      scale_action {
        cooldown  = "5"
        direction = "Increase"
        type      = "ChangeCount"
        value     = "1"
      }

      metric_trigger {
        metric_name        = "Percentage CPU"
        namespace          = "microsoft.compute/virtualmachinescalesets"
        resource_id        = azurerm_virtual_machine_scale_set.example.id
        threshold          = 80
        time_grain         = "PT1M"
        time_window        = "PT5M"
        time_aggregation_type = "Average"
        metric_resource_id = azurerm_virtual_machine_scale_set.example.id
        operator           = "GreaterThan"
      }
    }

    rule {
      name        = "example-rule2"
      scale_action {
        cooldown  = "5"
        direction = "Decrease"
        type      = "ChangeCount"
        value     = "1"
      }

      metric_trigger {
        metric_name        = "Percentage CPU"
        namespace          = "microsoft.compute/virtualmachinescalesets"
        resource_id        = azurerm_virtual_machine_scale_set.example.id
        threshold          = 20
        time_grain         = "PT1M"
        time_window        = "PT5M"
        time_aggregation_type = "Average"
        metric_resource_id = azurerm_virtual_machine_scale_set.example.id
        operator           = "LessThan"
      }
    }
  }
}