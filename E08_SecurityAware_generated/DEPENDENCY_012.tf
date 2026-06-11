variable "project" {
  type        = string
  description = "GCP project ID"
}

variable "region" {
  type        = string
  description = "GCP region"
}

variable "cluster_name" {
  type        = string
  description = "GKE cluster name"
}

variable "node_pool_name" {
  type        = string
  description = "GKE node pool name"
}

variable "node_pool_tags" {
  type        = list(string)
  description = "GKE node pool tags"
}

variable "node_count" {
  type        = number
  description = "Number of nodes in the node pool"
}

variable "machine_type" {
  type        = string
  description = "Machine type for the nodes"
}

variable "disk_size_gb" {
  type        = number
  description = "Disk size for the nodes"
}

variable "ssh_source_cidr" {
  type        = string
  description = "CIDR for SSH access"
}

provider "google" {
  project = var.project
  region  = var.region
}

resource "google_container_node_pool" "primary" {
  name       = var.node_pool_name
  cluster    = google_container_cluster.primary.name
  node_count = var.node_count

  node_config {
    machine_type = var.machine_type
    disk_size_gb = var.disk_size_gb

    metadata = {
      disable-legacy-endpoints = "true"
    }

    oauth_scopes = [
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]

    tags = var.node_pool_tags
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }
}

resource "google_container_cluster" "primary" {
  name               = var.cluster_name
  location          = var.region
  project            = var.project
  initial_node_count = 1

  private_cluster_config {
    enable_private_nodes = true
  }

  master_auth {
    username = var.username
    password = var.password
  }

  network_policy {
    enabled = true
  }
}

resource "google_compute_firewall" "ssh" {
  name    = "ssh-firewall"
  network = google_container_cluster.primary.network

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = [var.ssh_source_cidr]
  target_tags   = var.node_pool_tags
}

variable "username" {
  type        = string
  sensitive   = true
  description = "GKE cluster admin username"
}

variable "password" {
  type        = string
  sensitive   = true
  description = "GKE cluster admin password"
}