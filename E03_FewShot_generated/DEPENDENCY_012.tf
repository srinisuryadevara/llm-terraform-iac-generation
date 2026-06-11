variable "project_id" {
  type        = string
  sensitive   = true
}

variable "cluster_name" {
  type        = string
}

variable "node_pool_name" {
  type        = string
}

variable "node_pool_location" {
  type        = string
}

variable "node_pool_node_count" {
  type        = number
}

variable "node_pool_machine_type" {
  type        = string
}

resource "google_container_node_pool" "primary" {
  name       = var.node_pool_name
  cluster    = var.cluster_name
  location   = var.node_pool_location
  project    = var.project_id
  node_count = var.node_pool_node_count

  node_config {
    machine_type = var.node_pool_machine_type
    preemptible  = false
    disk_size_gb = 50
    oauth_scopes = [
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]
  }
}