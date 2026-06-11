variable "project_id" {
  type        = string
  sensitive   = true
}

variable "cluster_name" {
  type        = string
  sensitive   = false
}

variable "node_pool_name" {
  type        = string
  sensitive   = false
}

variable "node_pool_location" {
  type        = string
  sensitive   = false
}

variable "node_pool_node_count" {
  type        = number
  sensitive   = false
}

variable "node_pool_machine_type" {
  type        = string
  sensitive   = false
}

variable "node_pool_disk_size_gb" {
  type        = number
  sensitive   = false
}

variable "node_pool_preemptible" {
  type        = bool
  sensitive   = false
}

variable "node_pool_autoscaling_min_node_count" {
  type        = number
  sensitive   = false
}

variable "node_pool_autoscaling_max_node_count" {
  type        = number
  sensitive   = false
}

provider "google" {
  project = var.project_id
}

resource "google_container_cluster" "primary" {
  name               = var.cluster_name
  location           = var.node_pool_location
  project            = var.project_id
  remove_default_node_pool = true
  labels = {
    environment = "dev"
  }
}

resource "google_container_node_pool" "primary" {
  name       = var.node_pool_name
  cluster    = google_container_cluster.primary.name
  location   = var.node_pool_location
  node_count = var.node_pool_node_count

  node_config {
    machine_type = var.node_pool_machine_type
    disk_size_gb = var.node_pool_disk_size_gb
    preemptible  = var.node_pool_preemptible
    oauth_scopes = [
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]
    labels = {
      environment = "dev"
    }
  }

  autoscaling {
    min_node_count = var.node_pool_autoscaling_min_node_count
    max_node_count = var.node_pool_autoscaling_max_node_count
  }

  lifecycle {
    create_before_destroy = true
  }
}

output "cluster_id" {
  value = google_container_cluster.primary.id
}

output "node_pool_id" {
  value = google_container_node_pool.primary.id
}

output "cluster_endpoint" {
  value = google_container_cluster.primary.endpoint
}