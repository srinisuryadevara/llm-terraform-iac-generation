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

resource "google_container_cluster" "primary" {
  name               = var.cluster_name
  location           = var.location
  project            = var.project_id
  initial_node_count = 1

  labels = {
    environment = "production"
    owner       = "devops"
  }
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

    labels = {
      environment = "production"
      owner       = "devops"
    }
  }

  labels = {
    environment = "production"
    owner       = "devops"
  }
}

output "cluster_id" {
  value       = google_container_cluster.primary.id
  description = "The ID of the GKE cluster"
}

output "cluster_endpoint" {
  value       = google_container_cluster.primary.endpoint
  description = "The endpoint of the GKE cluster"
}

output "node_pool_id" {
  value       = google_container_node_pool.primary.id
  description = "The ID of the GKE node pool"
}