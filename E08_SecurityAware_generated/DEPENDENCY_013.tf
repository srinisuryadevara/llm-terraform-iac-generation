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

variable "node_pool_location" {
  type        = string
  description = "GKE node pool location"
}

variable "node_pool_size" {
  type        = number
  description = "GKE node pool size"
}

variable "node_pool_machine_type" {
  type        = string
  description = "GKE node pool machine type"
}

variable "node_pool_disk_size" {
  type        = number
  description = "GKE node pool disk size"
}

variable "node_pool_tags" {
  type        = list(string)
  description = "GKE node pool tags"
}

variable "node_pool_labels" {
  type        = map(string)
  description = "GKE node pool labels"
}

resource "google_container_node_pool" "primary" {
  name       = var.node_pool_name
  cluster    = google_container_cluster.primary.name
  location   = var.node_pool_location
  node_count = var.node_pool_size

  node_config {
    machine_type = var.node_pool_machine_type
    disk_size_gb = var.node_pool_disk_size
    oauth_token {
      scopes = [
        "https://www.googleapis.com/auth/devstorage.read_only",
        "https://www.googleapis.com/auth/logging.write",
        "https://www.googleapis.com/auth/monitoring",
      ]
    }
    tags = var.node_pool_tags
    labels = var.node_pool_labels
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }

  timeouts {
    create = "30m"
    update = "30m"
    delete = "30m"
  }
}

resource "google_container_cluster" "primary" {
  name               = var.cluster_name
  location           = var.region
  project            = var.project
  initial_node_count = 1

  private_cluster_config {
    enable_private_nodes = true
  }

  ip_allocation_policy {
    cluster_secondary_range_name  = "pod-range"
    services_secondary_range_name = "services-range"
  }

  network_policy {
    enabled = true
  }

  depends_on = [
    google_compute_network.primary,
    google_compute_subnetwork.primary,
  ]
}

resource "google_compute_network" "primary" {
  name                    = "primary-network"
  project                 = var.project
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "primary" {
  name          = "primary-subnetwork"
  project       = var.project
  ip_cidr_range = "10.0.0.0/16"
  network       = google_compute_network.primary.id
  region        = var.region
}