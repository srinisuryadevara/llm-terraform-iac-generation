# Configure the Google Cloud Provider
provider "google" {
  project = var.project_id
  region  = var.region
}

# Create a GKE cluster with private nodes
resource "google_container_cluster" "primary" {
  name               = var.cluster_name
  location           = var.region
  project            = var.project_id
  node_pool {
    name               = var.node_pool_name
    node_count         = var.node_count
    vm_size            = var.node_size
    oauth_scopes       = var.oauth_scopes
  }
  private_cluster_config {
    enable_private_nodes = true
    master_ipv4_cidr_block = var.master_ipv4_cidr_block
  }
  master_authorized_networks_config {
    cidr_blocks {
      cidr_block   = var.authorized_network_cidr
      display_name = var.authorized_network_name
    }
  }
  workload_identity_config {
    workload_pool = var.workload_pool
  }
  network_policy {
    enabled = true
  }
  ip_allocation_policy {
    cluster_secondary_range_name  = var.cluster_secondary_range_name
    services_secondary_range_name = var.services_secondary_range_name
  }
  labels = {
    environment = "gke-cluster"
  }
}

# Create a GKE node pool
resource "google_container_node_pool" "primary" {
  name       = var.node_pool_name
  cluster    = google_container_cluster.primary.name
  node_count = var.node_count
  node_config {
    preemptible  = var.preemptible
    machine_type = var.node_size
    disk_size_gb = var.disk_size_gb
    oauth_scopes = var.oauth_scopes
    workload_metadata_config {
      node_metadata = "GKE_METADATA_SERVER"
    }
  }
  labels = {
    environment = "gke-node-pool"
  }
}

# Define input variables
variable "project_id" {
  type = string
}

variable "region" {
  type = string
}

variable "cluster_name" {
  type = string
}

variable "node_pool_name" {
  type = string
}

variable "node_count" {
  type = number
}

variable "node_size" {
  type = string
}

variable "oauth_scopes" {
  type = list(string)
}

variable "master_ipv4_cidr_block" {
  type = string
}

variable "authorized_network_cidr" {
  type = string
}

variable "authorized_network_name" {
  type = string
}

variable "workload_pool" {
  type = string
}

variable "cluster_secondary_range_name" {
  type = string
}

variable "services_secondary_range_name" {
  type = string
}

variable "preemptible" {
  type = bool
}

variable "disk_size_gb" {
  type = number
}

# Output key resource attributes
output "cluster_id" {
  value = google_container_cluster.primary.id
}

output "cluster_endpoint" {
  value = google_container_cluster.primary.endpoint
}

output "node_pool_id" {
  value = google_container_node_pool.primary.id
}