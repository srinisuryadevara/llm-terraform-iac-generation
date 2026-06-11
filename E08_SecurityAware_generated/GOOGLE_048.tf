provider "google" {
  project = var.project_id
  region  = var.region
}

variable "project_id" {
  type        = string
  description = "GCP Project ID"
}

variable "region" {
  type        = string
  description = "GCP Region"
}

variable "cluster_name" {
  type        = string
  description = "GKE Cluster Name"
}

variable "node_pool_name" {
  type        = string
  description = "GKE Node Pool Name"
}

variable "ssh_source_cidr" {
  type        = string
  description = "SSH Source CIDR"
}

variable "network_policy_name" {
  type        = string
  description = "Network Policy Name"
}

resource "google_compute_network" "vpc" {
  name                    = "gke-vpc"
  auto_create_subnetworks = false
  mtu                     = 1460
  tags                    = ["gke-vpc"]
}

resource "google_compute_subnetwork" "subnet" {
  name          = "gke-subnet"
  ip_cidr_range = "10.0.0.0/16"
  network       = google_compute_network.vpc.id
  region        = var.region
  tags          = ["gke-subnet"]
}

resource "google_container_cluster" "primary" {
  name               = var.cluster_name
  location           = var.region
  network            = google_compute_network.vpc.id
  subnetwork         = google_compute_subnetwork.subnet.id
  min_master_version = "1.24"
  node_pool {
    name       = var.node_pool_name
    node_count = 1
    node_config {
      preemptible  = true
      machine_type = "e2-medium"
      disk_size_gb = 50
      oauth_scopes = [
        "https://www.googleapis.com/auth/devstorage.read_only",
        "https://www.googleapis.com/auth/logging.write",
        "https://www.googleapis.com/auth/monitoring",
      ]
    }
  }
  private_cluster_config {
    enable_private_nodes = true
    master_ipv4_cidr_block = "10.0.1.0/28"
  }
  master_authorized_networks_config {
    cidr_blocks {
      cidr_block   = var.ssh_source_cidr
      display_name = "SSH Access"
    }
  }
  network_policy {
    enabled = true
  }
  tags = ["gke-cluster"]
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

resource "google_compute_firewall" "gke" {
  name    = "gke-firewall"
  network = google_compute_network.vpc.id
  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }
  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["gke-node"]
  tags          = ["gke-firewall"]
}

resource "google_compute_network_policy" "policy" {
  name                    = var.network_policy_name
  provider                = google
  description             = "Network policy for GKE cluster"
  ingress {
    rules {
      action = "allow"
      ports {
        port     = 80
        protocol = "tcp"
      }
      from {
        ip_blocks = ["0.0.0.0/0"]
      }
    }
  }
  egress {
    rules {
      action = "allow"
      ports {
        port     = 443
        protocol = "tcp"
      }
      to {
        ip_blocks = ["0.0.0.0/0"]
      }
    }
  }
  tags = ["gke-network-policy"]
}