provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_container_cluster" "private_cluster" {
  name               = var.cluster_name
  location           = var.region
  project            = var.project_id
  network            = var.network_name
  subnetwork         = var.subnetwork_name
  private_cluster_config {
    enable_private_nodes = true
    master_ipv4_cidr_block = var.master_ipv4_cidr_block
  }
  master_authorized_networks_config {
    cidr_blocks {
      cidr_block = var.authorized_network_cidr
      display_name = "Authorized Network"
    }
  }
  workload_identity_config {
    workload_pool = var.workload_pool
  }
  enable_shielded_nodes = true
  enable_intranode_visibility = true
  logging_config {
    enable_components = ["SYSTEM_COMPONENTS", "WORKLOADS"]
  }
  monitoring_config {
    enable_components = ["SYSTEM_COMPONENTS", "WORKLOADS"]
  }
  tags = {
    Environment = var.environment
    Project     = var.project_id
  }
}

resource "google_container_node_pool" "private_node_pool" {
  name       = var.node_pool_name
  cluster    = google_container_cluster.private_cluster.name
  location   = var.region
  project    = var.project_id
  node_count = var.node_count
  node_config {
    preemptible  = var.preemptible
    machine_type = var.machine_type
    disk_size_gb = var.disk_size_gb
    oauth_scopes = [
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]
    workload_metadata_config {
      mode = "GKE_METADATA"
    }
    shielded_instance_config {
      enable_secure_boot = true
    }
  }
  management {
    auto_repair  = true
    auto_upgrade = true
  }
  tags = {
    Environment = var.environment
    Project     = var.project_id
  }
}

resource "google_compute_firewall" "ssh_firewall" {
  name    = var.ssh_firewall_name
  network = var.network_name
  project = var.project_id
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  source_ranges = [var.ssh_source_cidr]
  target_tags   = ["gke-node"]
  depends_on    = [google_container_cluster.private_cluster]
  tags = {
    Environment = var.environment
    Project     = var.project_id
  }
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

variable "network_name" {
  type        = string
  description = "GCP Network Name"
}

variable "subnetwork_name" {
  type        = string
  description = "GCP Subnetwork Name"
}

variable "master_ipv4_cidr_block" {
  type        = string
  description = "Master Authorized Network CIDR Block"
}

variable "authorized_network_cidr" {
  type        = string
  description = "Authorized Network CIDR Block"
}

variable "workload_pool" {
  type        = string
  description = "Workload Identity Pool"
}

variable "node_pool_name" {
  type        = string
  description = "GKE Node Pool Name"
}

variable "node_count" {
  type        = number
  description = "GKE Node Count"
}

variable "preemptible" {
  type        = bool
  description = "GKE Node Preemptibility"
}

variable "machine_type" {
  type        = string
  description = "GKE Node Machine Type"
}

variable "disk_size_gb" {
  type        = number
  description = "GKE Node Disk Size"
}

variable "ssh_firewall_name" {
  type        = string
  description = "GCP SSH Firewall Name"
}

variable "ssh_source_cidr" {
  type        = string
  description = "GCP SSH Source CIDR Block"
}

variable "environment" {
  type        = string
  description = "Environment"
}