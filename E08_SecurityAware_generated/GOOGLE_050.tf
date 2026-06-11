provider "google" {
  project = var.project_id
  region  = var.region
}

variable "project_id" {
  type        = string
  description = "GCP project ID"
}

variable "region" {
  type        = string
  description = "GCP region"
}

variable "ssh_source_cidr" {
  type        = string
  description = "CIDR for SSH access"
}

variable "cluster_name" {
  type        = string
  description = "GKE cluster name"
}

variable "node_pool_name" {
  type        = string
  description = "GKE node pool name"
}

variable "node_count" {
  type        = number
  description = "Number of nodes in the node pool"
}

variable "machine_type" {
  type        = string
  description = "Machine type for the nodes"
}

resource "google_compute_network" "vpc" {
  name                    = "gke-vpc"
  auto_create_subnetworks = false
  mtu                     = 1460
  tags                    = ["gke-vpc"]
}

resource "google_compute_subnetwork" "gke-subnet" {
  name          = "gke-subnet"
  ip_cidr_range = "10.0.0.0/16"
  network       = google_compute_network.vpc.id
  region        = var.region
  tags          = ["gke-subnet"]
}

resource "google_compute_firewall" "ssh" {
  name    = "gke-ssh-firewall"
  network = google_compute_network.vpc.id
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  source_ranges = [var.ssh_source_cidr]
  target_tags   = ["gke-node"]
  tags          = ["gke-ssh-firewall"]
}

resource "google_container_cluster" "gke-cluster" {
  name               = var.cluster_name
  location           = var.region
  network            = google_compute_network.vpc.id
  subnetwork         = google_compute_subnetwork.gke-subnet.id
  min_master_version = "1.23.0-gke.1000"
  node_pool {
    name       = var.node_pool_name
    node_count = var.node_count
    node_config {
      machine_type = var.machine_type
      oauth_scopes = [
        "https://www.googleapis.com/auth/devstorage.read_only",
        "https://www.googleapis.com/auth/logging.write",
        "https://www.googleapis.com/auth/monitoring",
      ]
      tags = ["gke-node"]
    }
  }
  private_cluster_config {
    enable_private_nodes = true
  }
  network_policy {
    enabled = true
  }
  encryption_config {
    kms_key_name = google_kms_key.gke-kms-key.id
  }
  tags = ["gke-cluster"]
}

resource "google_kms_key_ring" "gke-kms-key-ring" {
  name     = "gke-kms-key-ring"
  location = var.region
  tags     = ["gke-kms-key-ring"]
}

resource "google_kms_key" "gke-kms-key" {
  name            = "gke-kms-key"
  key_ring        = google_kms_key_ring.gke-kms-key-ring.id
  rotation_period = "7776000s"
  tags            = ["gke-kms-key"]
}

resource "google_kms_crypto_key_version" "gke-kms-key-version" {
  crypto_key = google_kms_key.gke-kms-key.id
}

resource "google_compute_network_policy" "gke-network-policy" {
  name                    = "gke-network-policy"
  project                 = var.project_id
  provider                = google
  description             = "GKE network policy"
  ingress_policy          = "ALLOW_FROM_SAME_L7ILBNP"
  egress_policy           = "ALLOW_EGRESS_TO_SAME_L7ILBNP"
  depends_on              = [google_container_cluster.gke-cluster]
  tags                    = ["gke-network-policy"]
}