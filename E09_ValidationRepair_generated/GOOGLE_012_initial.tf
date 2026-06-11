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
}

resource "google_container_node_pool" "primary" {
  name       = var.node_pool_name
  cluster    = google_container_cluster.primary.name
  node_count = var.node_count
  location   = var.region
  project    = var.project_id

  node_config {
    preemptible  = var.preemptible
    machine_type = var.machine_type
    disk_size_gb = var.disk_size_gb
    oauth_scopes = [
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]
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