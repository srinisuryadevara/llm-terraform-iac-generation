# ---------------------------------------------------------------------------------------------------------------------
# REQUIRE A SPECIFIC TERRAFORM VERSION OR HIGHER
# This module uses terraform 0.12 syntax and features that are available only since version 0.12.6, however
# we now depend on a bug fix released in 0.12.7.
# ----------------------------------------------------------------------------------------------------------------------
terraform {
  required_version = ">= 0.12.7"
}

# ---------------------------------------------------------------------------------------------------------------------
# Configure the Google Cloud Provider
# ---------------------------------------------------------------------------------------------------------------------
provider "google" {
  project = var.project
  region  = var.region
}

# ---------------------------------------------------------------------------------------------------------------------
# Configure the Google Cloud Beta Provider
# ---------------------------------------------------------------------------------------------------------------------
provider "google-beta" {
  project = var.project
  region  = var.region
}

# ---------------------------------------------------------------------------------------------------------------------
# Create a GKE node pool
# ---------------------------------------------------------------------------------------------------------------------
resource "google_container_node_pool" "node_pool" {
  provider = google-beta
  name       = var.node_pool_name
  location   = var.location
  cluster    = var.cluster_name
  node_count = var.node_count

  node_config {
    preemptible  = var.preemptible
    machine_type = var.machine_type
    disk_size_gb = var.disk_size_gb
    oauth_scopes = var.oauth_scopes
  }

  autoscaling {
    min_node_count = var.min_node_count
    max_node_count = var.max_node_count
  }

  management {
    auto_repair  = var.auto_repair
    auto_upgrade = var.auto_upgrade
  }

  upgrade_settings {
    max_surge       = var.max_surge
    max_unavailable = var.max_unavailable
  }
}

variable "project" {
  type        = string
  description = "The ID of the project to create the cluster in"
}

variable "location" {
  type        = string
  description = "The location to create the cluster in"
}

variable "node_pool_name" {
  type        = string
  description = "The name of the node pool"
}

variable "cluster_name" {
  type        = string
  description = "The name of the cluster to create the node pool in"
}

variable "node_count" {
  type        = number
  description = "The number of nodes to create in the node pool"
}

variable "preemptible" {
  type        = bool
  description = "Whether the nodes in the node pool are preemptible"
}

variable "machine_type" {
  type        = string
  description = "The machine type to use for the nodes in the node pool"
}

variable "disk_size_gb" {
  type        = number
  description = "The size of the disk to use for the nodes in the node pool"
}

variable "oauth_scopes" {
  type        = list(string)
  description = "The OAuth scopes to use for the nodes in the node pool"
}

variable "min_node_count" {
  type        = number
  description = "The minimum number of nodes to create in the node pool"
}

variable "max_node_count" {
  type        = number
  description = "The maximum number of nodes to create in the node pool"
}

variable "auto_repair" {
  type        = bool
  description = "Whether to automatically repair the nodes in the node pool"
}

variable "auto_upgrade" {
  type        = bool
  description = "Whether to automatically upgrade the nodes in the node pool"
}

variable "max_surge" {
  type        = number
  description = "The maximum number of nodes to surge during an upgrade"
}

variable "max_unavailable" {
  type        = number
  description = "The maximum number of nodes to make unavailable during an upgrade"
}