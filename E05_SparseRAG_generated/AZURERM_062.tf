# Configure the Azure Provider
provider "azurerm" {
  features {}
}

# Create a resource group
resource "azurerm_resource_group" "example" {
  name     = var.resource_group_name
  location = var.location
}

# Create a virtual network
resource "azurerm_virtual_network" "example" {
  name                = var.virtual_network_name
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
}

# Create a subnet
resource "azurerm_subnet" "example" {
  name                 = var.subnet_name
  resource_group_name = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.example.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Create a public IP address
resource "azurerm_public_ip" "example" {
  name                = var.public_ip_name
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  allocation_method   = "Dynamic"
}

# Create a load balancer
resource "azurerm_lb" "example" {
  name                = var.load_balancer_name
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name

  frontend_ip_configuration {
    name                 = var.frontend_ip_configuration_name
    public_ip_address_id = azurerm_public_ip.example.id
  }
}

# Create a load balancer backend address pool
resource "azurerm_lb_backend_address_pool" "example" {
  loadbalancer_id = azurerm_lb.example.id
  name            = var.backend_address_pool_name
}

# Create a load balancer rule
resource "azurerm_lb_rule" "example" {
  loadbalancer_id                = azurerm_lb.example.id
  name                           = var.load_balancer_rule_name
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = var.frontend_ip_configuration_name
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.example.id]
}

# Create a virtual machine scale set
resource "azurerm_linux_virtual_machine_scale_set" "example" {
  name                = var.virtual_machine_scale_set_name
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  sku                 = "Standard_DS1_v2"
  instances           = 2
  admin_username      = var.admin_username
  admin_ssh_key {
    username   = var.admin_username
    public_key = file("${path.module}/ssh-keys/terraform-azure.pub")
  }
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
  source_image_reference {
    publisher = "RedHat"
    offer     = "RHEL"
    sku       = "83-gen2"
    version   = "latest"
  }
  custom_data = filebase64("${path.module}/app-scripts/app1-cloud-init.txt")
  network_interface {
    name    = var.network_interface_name
    primary = true
    ip_configuration {
      name                                   = var.ip_configuration_name
      primary                               = true
      subnet_id                             = azurerm_subnet.example.id
      load_balancer_id                      = azurerm_lb.example.id
      load_balancer_backend_address_pool_ids = [azurerm_lb_backend_address_pool.example.id]
    }
  }
}

# Create an autoscale setting
resource "azurerm_monitor_autoscale_setting" "example" {
  name                = var.autoscale_setting_name
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  target_resource_id  = azurerm_linux_virtual_machine_scale_set.example.id

  profile {
    name = var.profile_name

    capacity {
      default = 2
      minimum = 2
      maximum = 10
    }

    rule {
      name      = var.rule_name
      scale_action {
        cooldown  = "5"
        direction = "Increase"
        type      = "ChangeCount"
        value     = "1"
      }
      metric_trigger {
        metric_name        = "Percentage CPU"
        namespace          = "microsoft.compute/virtualmachinescalesets"
        operator           = "GreaterThan"
        statistic          = "Average"
        threshold          = 75
        time_aggregation   = "Average"
        time_grain         = "PT1M"
        time_window        = "PT5M"
        metric_resource_id = azurerm_linux_virtual_machine_scale_set.example.id
      }
    }

    rule {
      name      = var.rule_name_decrease
      scale_action {
        cooldown  = "5"
        direction = "Decrease"
        type      = "ChangeCount"
        value     = "1"
      }
      metric_trigger {
        metric_name        = "Percentage CPU"
        namespace          = "microsoft.compute/virtualmachinescalesets"
        operator           = "LessThan"
        statistic          = "Average"
        threshold          = 25
        time_aggregation   = "Average"
        time_grain         = "PT1M"
        time_window        = "PT5M"
        metric_resource_id = azurerm_linux_virtual_machine_scale_set.example.id
      }
    }
  }
}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "virtual_network_name" {
  type = string
}

variable "subnet_name" {
  type = string
}

variable "public_ip_name" {
  type = string
}

variable "load_balancer_name" {
  type = string
}

variable "frontend_ip_configuration_name" {
  type = string
}

variable "backend_address_pool_name" {
  type = string
}

variable "load_balancer_rule_name" {
  type = string
}

variable "virtual_machine_scale_set_name" {
  type = string
}

variable "admin_username" {
  type = string
}

variable "network_interface_name" {
  type = string
}

variable "ip_configuration_name" {
  type = string
}

variable "autoscale_setting_name" {
  type = string
}

variable "profile_name" {
  type = string
}

variable "rule_name" {
  type = string
}

variable "rule_name_decrease" {
  type = string
}