provider "azurerm" {
  features {}
}

variable "location" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "vmss_name" {
  type = string
}

variable "admin_username" {
  type = string
}

variable "admin_password" {
  type      = string
  sensitive = true
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
  name                = "example-pip"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  allocation_method  = "Dynamic"
}

resource "azurerm_lb" "example" {
  name                = "example-lb"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  sku                 = "Standard"
  frontend_ip_configuration {
    name                 = "example-fip"
    public_ip_address_id = azurerm_public_ip.example.id
  }
}

resource "azurerm_lb_backend_address_pool" "example" {
  loadbalancer_id = azurerm_lb.example.id
  name            = "example-bap"
}

resource "azurerm_lb_rule" "example" {
  loadbalancer_id                = azurerm_lb.example.id
  name                           = "example-lbr"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "example-fip"
  backend_address_pool_ids        = [azurerm_lb_backend_address_pool.example.id]
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

  storage_profile_image_reference {
    publisher = "Canonical"
    offer       = "UbuntuServer"
    sku         = "16.04-LTS"
    version     = "latest"
  }

  storage_profile_os_disk {
    name              = ""
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
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
    name    = "example-np"
    primary = true

    ip_configuration {
      name                                   = "example-ip"
      primary                               = true
      subnet_id                             = azurerm_subnet.example.id
      load_balancer_backend_address_pool_ids = [azurerm_lb_backend_address_pool.example.id]
    }
  }
}

resource "azurerm_monitor_autoscale_setting" "example" {
  name                = "example-asc"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name

  target_resource_id = azurerm_virtual_machine_scale_set.example.id

  profile {
    name = "example-profile"

    capacity {
      default = 2
      minimum = 2
      maximum = 5
    }

    rule {
      name      = "example-rule"
      scale_action {
        cooldown  = "300"
        direction = "Increase"
        type       = "ChangeCount"
        value      = "1"
      }
      metric_trigger {
        metric_name        = "Percentage CPU"
        namespace          = "microsoft.compute/virtualmachinescalesets"
        resource_id        = azurerm_virtual_machine_scale_set.example.id
        statistic         = "Average"
        threshold         = 80
        time_aggregation = "Average"
        time_grain        = "PT1M"
        time_window       = "PT5M"
        metric_resource_id = azurerm_virtual_machine_scale_set.example.id
        operator           = "GreaterThan"
      }
    }

    rule {
      name      = "example-rule2"
      scale_action {
        cooldown  = "300"
        direction = "Decrease"
        type       = "ChangeCount"
        value      = "1"
      }
      metric_trigger {
        metric_name        = "Percentage CPU"
        namespace          = "microsoft.compute/virtualmachinescalesets"
        resource_id        = azurerm_virtual_machine_scale_set.example.id
        statistic         = "Average"
        threshold         = 20
        time_aggregation = "Average"
        time_grain        = "PT1M"
        time_window       = "PT5M"
        metric_resource_id = azurerm_virtual_machine_scale_set.example.id
        operator           = "LessThan"
      }
    }
  }
}