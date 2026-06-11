provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_container_cluster" "private_cluster" {
  name               = var.cluster_name
  location           = var.region
  node_pool {
    name       = "default-pool"
    node_count = 1
  }
  private_cluster_config {
    enable_private_nodes = true
    master_ipv4_cidr_block = "10.0.0.0/28"
  }
  master_authorized_networks_config {
    cidr_blocks {
      cidr_block = var.authorized_network
      display_name = "Authorized Network"
    }
  }
  workload_identity_config {
    workload_pool = var.workload_pool
  }
  ip_allocation_policy {
    cluster_secondary_range_name  = "pod-range"
    services_secondary_range_name = "service-range"
  }
}

resource "google_container_node_pool" "private_nodes" {
  name       = "private-nodes"
  cluster    = google_container_cluster.private_cluster.name
  location   = var.region
  node_count = 1

  node_config {
    preemptible  = false
    machine_type = "n1-standard-1"
    disk_size_gb = 50
    oauth_scopes = [
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
      "https://www.googleapis.com/auth/servicecontrol",
      "https://www.googleapis.com/auth/service.management.readonly",
      "https://www.googleapis.com/auth/trace.append",
    ]
  }
}

variable "project_id" {
  type = string
}

variable "region" {
  type = string
}

variable "cluster_name" {
  type = string
}

variable "authorized_network" {
  type = string
}

variable "workload_pool" {
  type = string
}