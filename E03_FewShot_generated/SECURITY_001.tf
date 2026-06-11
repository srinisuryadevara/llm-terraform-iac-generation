provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_container_cluster" "primary" {
  name               = var.cluster_name
  location           = var.region
  project            = var.project_id
  node_pool {
    name               = "default-pool"
    node_count         = var.node_count
    vm_size            = var.node_size
    preemptible       = var.preemptible
    max_pods_per_node  = var.max_pods_per_node
  }
  private_cluster_config {
    enable_private_nodes = true
    master_ipv4_cidr_block = var.master_ipv4_cidr_block
  }
  master_authorized_networks_config {
    cidr_blocks {
      cidr_block   = var.authorized_network_cidr
      display_name = "Authorized Network"
    }
  }
  workload_identity_config {
    workload_pool = var.workload_pool
  }
  network_policy {
    enabled = var.network_policy_enabled
  }
  ip_allocation_policy {
    cluster_secondary_range_name  = var.cluster_secondary_range_name
    services_secondary_range_name = var.services_secondary_range_name
  }
}

resource "google_container_node_pool" "primary" {
  name       = "primary-pool"
  cluster    = google_container_cluster.primary.name
  node_count = var.node_count
  location   = var.region
  project    = var.project_id
  node_config {
    preemptible  = var.preemptible
    machine_type = var.node_size
    disk_size_gb = var.disk_size_gb
    oauth_scopes = var.oauth_scopes
    workload_metadata_config {
      mode = var.workload_metadata_mode
    }
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

variable "node_count" {
  type = number
}

variable "node_size" {
  type = string
}

variable "preemptible" {
  type = bool
}

variable "max_pods_per_node" {
  type = number
}

variable "master_ipv4_cidr_block" {
  type = string
}

variable "authorized_network_cidr" {
  type = string
}

variable "workload_pool" {
  type = string
}

variable "network_policy_enabled" {
  type = bool
}

variable "cluster_secondary_range_name" {
  type = string
}

variable "services_secondary_range_name" {
  type = string
}

variable "disk_size_gb" {
  type = number
}

variable "oauth_scopes" {
  type = list(string)
}

variable "workload_metadata_mode" {
  type = string
}