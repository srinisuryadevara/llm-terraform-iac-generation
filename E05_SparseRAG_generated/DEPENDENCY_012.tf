# ---------------------------------------------------------------------------------------------------------------------
# REQUIRE A SPECIFIC TERRAFORM VERSION OR HIGHER
# This module uses terraform 0.12 syntax and features that are available only since version 0.12.6, however
# we now depend on a bug fix released in 0.12.7.
# ----------------------------------------------------------------------------------------------------------------------
terraform {
  required_version = ">= 0.12.7"
}

# ---------------------------------------------------------------------------------------------------------------------
# Create the GKE Node Pool
# We want to make a node pool with a specific configuration and manage it with the fine-grained google_container_node_pool resource
# ---------------------------------------------------------------------------------------------------------------------

resource "google_container_node_pool" "node_pool" {
  provider = google-beta

  name       = var.name
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

variable "name" {
  type        = string
  description = "The name of the node pool"
}

variable "location" {
  type        = string
  description = "The location of the node pool"
}

variable "cluster_name" {
  type        = string
  description = "The name of the parent cluster"
}

variable "node_count" {
  type        = number
  description = "The number of nodes in the node pool"
}

variable "preemptible" {
  type        = bool
  description = "Whether the nodes are preemptible"
}

variable "machine_type" {
  type        = string
  description = "The machine type of the nodes"
}

variable "disk_size_gb" {
  type        = number
  description = "The disk size of the nodes in GB"
}

variable "oauth_scopes" {
  type        = list(string)
  description = "The OAuth scopes of the nodes"
}

variable "min_node_count" {
  type        = number
  description = "The minimum number of nodes in the node pool"
}

variable "max_node_count" {
  type        = number
  description = "The maximum number of nodes in the node pool"
}

variable "auto_repair" {
  type        = bool
  description = "Whether to automatically repair nodes"
}

variable "auto_upgrade" {
  type        = bool
  description = "Whether to automatically upgrade nodes"
}

variable "max_surge" {
  type        = number
  description = "The maximum number of nodes that can be surged during an upgrade"
}

variable "max_unavailable" {
  type        = number
  description = "The maximum number of nodes that can be unavailable during an upgrade"
}