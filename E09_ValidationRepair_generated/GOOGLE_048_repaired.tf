provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_container_cluster" "primary" {
  name               = var.cluster_name
  location           = var.region
  project            = var.project_id
  network_policy {
    enabled = true
  }
  labels = {
    environment = "production"
    owner       = "terraform"
  }
}

resource "google_container_node_pool" "primary" {
  name       = var.node_pool_name
  cluster    = google_container_cluster.primary.name
  node_count = var.node_count
  project    = var.project_id
  location   = var.region

  node_config {
    preemptible  = var.preemptible
    machine_type = var.machine_type
    disk_size_gb = var.disk_size_gb
    oauth_scopes = var.oauth_scopes
  }
  labels = {
    environment = "production"
    owner       = "terraform"
  }
}

variable "project_id" {
  type        = string
  sensitive   = true
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

variable "preemptible" {
  type = bool
}

variable "machine_type" {
  type = string
}

variable "disk_size_gb" {
  type = number
}

variable "oauth_scopes" {
  type = list(string)
}

output "cluster_id" {
  value = google_container_cluster.primary.id
}

output "cluster_endpoint" {
  value = google_container_cluster.primary.endpoint
}

output "node_pool_id" {
  value = google_container_node_pool.primary.id
}