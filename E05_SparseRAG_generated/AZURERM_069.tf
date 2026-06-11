variable "resource_group_name_prefix" {
  type = string
}

variable "resource_group_location" {
  type = string
}

variable "vnet_cidrs" {
  type = list(string)
}

variable "vnet_subnets" {
  type = map(string)
}

variable "subnet_delegation" {
  type = map(string)
}

variable "network_region" {
  type = string
}

variable "cluster_id" {
  type = string
}

data "azurerm_subscription" "current" {}

resource "random_pet" "rg_name" {
  prefix = var.resource_group_name_prefix
}

resource "azurerm_resource_group" "rg" {
  name     = "${var.cluster_id}-gid"
  location = var.network_region
}

resource "azurerm_route_table" "rt" {
  name                = "${var.cluster_id}-rt"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
}

resource "azurerm_network_security_group" "nsg" {
  name                = "${var.cluster_id}-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

module "network" {
  source              = "Azure/vnet/azurerm"
  version             = "~> 2.6.0"
  address_space       = var.vnet_cidrs
  resource_group_name = azurerm_resource_group.rg.name
  subnet_delegation   = var.subnet_delegation
  subnet_names        = keys(var.vnet_subnets)
  subnet_prefixes     = values(var.vnet_subnets)
  vnet_name           = "${var.cluster_id}-vnet"
  vnet_location       = var.network_region

  # Every subnet will share a single route table
  route_tables_ids = { for i, subnet in keys(var.vnet_subnets) : subnet => azurerm_route_table.rt.id }

  # Every subnet will share a single network security group
  nsg_ids = { for i, subnet in keys(var.vnet_subnets) : subnet => azurerm_network_security_group.nsg.id }

  depends_on = [azurerm_resource_group.rg]
}