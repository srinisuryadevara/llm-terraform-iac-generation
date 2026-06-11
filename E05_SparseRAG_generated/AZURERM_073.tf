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

  sku {
    name     = var.virtual_machine_size
    tier     = "Standard"
    capacity = var.initial_instance_count
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = var.image_publisher
    offer     = var.image_offer
    sku       = var.image_sku
    version   = var.image_version
  }

  admin_ssh_key {
    username   = var.admin_username
    public_key = file("${path.module}/ssh-keys/terraform-azure.pub")
  }

  network_interface {
    name    = var.network_interface_name
    primary = true

    ip_configuration {
      name                                   = var.ip_configuration_name
      primary                                 = true
      subnet_id                              = azurerm_subnet.example.id
      load_balancer_backend_address_pool_ids = [azurerm_lb_backend_address_pool.example.id]
    }
  }

  custom_data = filebase64("${path.module}/app-scripts/app1-cloud-init.txt")

  tags = var.common_tags
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
      default = var.initial_instance_count
      minimum = var.minimum_instance_count
      maximum = var.maximum_instance_count
    }

    rule {
      name      = var.rule_name
      scale_action {
        cooldown  = var.cooldown
        direction = var.direction
        type      = var.scale_action_type
        value     = var.scale_action_value
      }

      metric_trigger {
        metric_name        = var.metric_name
        namespace          = var.namespace
        operator           = var.operator
        statistic          = var.statistic
        threshold          = var.threshold
        time_aggregation   = var.time_aggregation
        time_grain         = var.time_grain
        time_window        = var.time_window
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

variable "virtual_machine_size" {
  type = string
}

variable "initial_instance_count" {
  type = number
}

variable "image_publisher" {
  type = string
}

variable "image_offer" {
  type = string
}

variable "image_sku" {
  type = string
}

variable "image_version" {
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

variable "common_tags" {
  type = map(string)
}

variable "autoscale_setting_name" {
  type = string
}

variable "profile_name" {
  type = string
}

variable "minimum_instance_count" {
  type = number
}

variable "maximum_instance_count" {
  type = number
}

variable "rule_name" {
  type = string
}

variable "cooldown" {
  type = number
}

variable "direction" {
  type = string
}

variable "scale_action_type" {
  type = string
}

variable "scale_action_value" {
  type = number
}

variable "metric_name" {
  type = string
}

variable "namespace" {
  type = string
}

variable "operator" {
  type = string
}

variable "statistic" {
  type = string
}

variable "threshold" {
  type = number
}

variable "time_aggregation" {
  type = string
}

variable "time_grain" {
  type = string
}

variable "time_window" {
  type = string
}