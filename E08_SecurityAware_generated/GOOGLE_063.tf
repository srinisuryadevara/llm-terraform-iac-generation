provider "google" {
  project = var.project_id
  region  = var.region
}

variable "project_id" {
  type        = string
  sensitive   = true
  description = "GCP Project ID"
}

variable "region" {
  type        = string
  description = "GCP Region"
}

variable "ssh_source_cidr" {
  type        = string
  description = "SSH source CIDR"
}

variable "cluster_name" {
  type        = string
  description = "GKE Cluster name"
}

variable "node_pool_name" {
  type        = string
  description = "GKE Node pool name"
}

variable "node_count" {
  type        = number
  description = "Number of nodes in the node pool"
}

variable "machine_type" {
  type        = string
  description = "Machine type for the nodes"
}

variable "network_name" {
  type        = string
  description = "Network name"
}

variable "subnet_name" {
  type        = string
  description = "Subnet name"
}

resource "google_compute_network" "vpc" {
  name                    = var.network_name
  auto_create_subnetworks = false
  mtu                     = 1460
  tags                    = ["gke-cluster", "network-policy-enabled"]
}

resource "google_compute_subnetwork" "subnet" {
  name          = var.subnet_name
  ip_cidr_range = "10.0.0.0/16"
  network       = google_compute_network.vpc.id
  region        = var.region
  tags          = ["gke-cluster", "network-policy-enabled"]
}

resource "google_compute_firewall" "ssh" {
  name    = "ssh-firewall"
  network = google_compute_network.vpc.name
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  source_ranges = [var.ssh_source_cidr]
  target_tags   = ["gke-cluster"]
}

resource "google_container_cluster" "primary" {
  name               = var.cluster_name
  location           = var.region
  network            = google_compute_network.vpc.name
  subnetwork         = google_compute_subnetwork.subnet.name
  node_pool {
    name       = var.node_pool_name
    node_count = var.node_count
    node_config {
      machine_type = var.machine_type
      disk_size_gb = 50
      oauth_scopes = [
        "https://www.googleapis.com/auth/devstorage.read_only",
        "https://www.googleapis.com/auth/logging.write",
        "https://www.googleapis.com/auth/monitoring",
      ]
    }
  }
  network_policy {
    enabled = true
  }
  private_cluster_config {
    enable_private_nodes = true
  }
  depends_on = [
    google_compute_network.vpc,
    google_compute_subnetwork.subnet,
  ]
  tags = ["gke-cluster", "network-policy-enabled"]
}

resource "google_container_node_pool" "primary" {
  name       = var.node_pool_name
  cluster    = google_container_cluster.primary.name
  location   = var.region
  node_count = var.node_count
  node_config {
    machine_type = var.machine_type
    disk_size_gb = 50
    oauth_scopes = [
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]
  }
  depends_on = [
    google_container_cluster.primary,
  ]
  tags = ["gke-cluster", "network-policy-enabled"]
}