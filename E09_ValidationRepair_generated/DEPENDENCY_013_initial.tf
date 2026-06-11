variable "project_id" {
  type        = string
  sensitive   = true
}

variable "location" {
  type        = string
  sensitive   = false
}

variable "cluster_name" {
  type        = string
  sensitive   = false
}

variable "node_pool_name" {
  type        = string
  sensitive   = false
}

variable "node_count" {
  type        = number
  sensitive   = false
}

variable "machine_type" {
  type        = string
  sensitive   = false
}

resource "google_container_node_pool" "primary" {
  name       = var.node_pool_name
  cluster    = google_container_cluster.primary.name
  location   = var.location
  project    = var.project_id
  node_count = var.node_count

  node_config {
    machine_type = var.machine_type
    preemptible  = false
    disk_size_gb = 50
    oauth_scopes = [
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]
  }
}

resource "google_container_cluster" "primary" {
  name               = var.cluster_name
  location           = var.location
  project            = var.project_id
  initial_node_count = 1
}