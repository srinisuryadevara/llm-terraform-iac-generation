provider "google" {
  project = var.project_id
  region  = var.region
}

variable "project_id" {
  type        = string
  sensitive   = true
  description = "The ID of the project to create the resources in"
}

variable "region" {
  type        = string
  description = "The region to create the resources in"
}

variable "ssh_source_cidr" {
  type        = string
  description = "The source CIDR for SSH access"
}

variable "gke_cluster_name" {
  type        = string
  description = "The name of the GKE cluster"
}

variable "gke_node_pool_name" {
  type        = string
  description = "The name of the GKE node pool"
}

variable "gke_node_pool_machine_type" {
  type        = string
  description = "The machine type for the GKE node pool"
}

variable "gke_node_pool_num_nodes" {
  type        = number
  description = "The number of nodes in the GKE node pool"
}

resource "google_compute_network" "gke_network" {
  name                    = "${var.gke_cluster_name}-network"
  auto_create_subnetworks = false
  mtu                     = 1460
  tags                    = ["gke-network", var.gke_cluster_name]
}

resource "google_compute_subnetwork" "gke_subnetwork" {
  name          = "${var.gke_cluster_name}-subnetwork"
  ip_cidr_range = "10.0.0.0/16"
  network       = google_compute_network.gke_network.id
  region        = var.region
  tags          = ["gke-subnetwork", var.gke_cluster_name]
}

resource "google_container_cluster" "gke_cluster" {
  name               = var.gke_cluster_name
  location           = var.region
  project            = var.project_id
  network            = google_compute_network.gke_network.name
  subnetwork         = google_compute_subnetwork.gke_subnetwork.name
  min_master_version = "1.23"
  node_pool {
    name               = var.gke_node_pool_name
    node_count         = var.gke_node_pool_num_nodes
    vm_size            = var.gke_node_pool_machine_type
    autoscaling {
      min_node_count = 1
      max_node_count = 3
    }
  }
  private_cluster_config {
    enable_private_nodes = true
    master_ipv4_cidr_block = "10.0.0.0/28"
  }
  network_policy {
    enabled = true
  }
  cluster_autoscaling {
    enabled = true
  }
  database_encryption {
    state    = "ENCRYPTED"
    key_name = "gke-cluster-key"
  }
  tags = ["gke-cluster", var.gke_cluster_name]
}

resource "google_compute_firewall" "gke_firewall" {
  name    = "${var.gke_cluster_name}-firewall"
  network = google_compute_network.gke_network.name
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  source_ranges = [var.ssh_source_cidr]
  target_tags   = ["gke-node"]
  tags          = ["gke-firewall", var.gke_cluster_name]
}

resource "google_kms_key_ring" "gke_key_ring" {
  name     = "${var.gke_cluster_name}-key-ring"
  location = var.region
  project  = var.project_id
  tags     = ["gke-key-ring", var.gke_cluster_name]
}

resource "google_kms_crypto_key" "gke_crypto_key" {
  name     = "gke-cluster-key"
  key_ring = google_kms_key_ring.gke_key_ring.id
  tags     = ["gke-crypto-key", var.gke_cluster_name]
}

resource "google_kms_crypto_key_version" "gke_crypto_key_version" {
  crypto_key = google_kms_crypto_key.gke_crypto_key.id
  tags       = ["gke-crypto-key-version", var.gke_cluster_name]
}