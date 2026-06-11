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
    oauth_scopes = var.oauth_scopes
  }
}

variable "project_id" {
  type        = string
  description = "The ID of the project to create the cluster in"
}

variable "region" {
  type        = string
  description = "The region to create the cluster in"
}

variable "cluster_name" {
  type        = string
  description = "The name of the cluster"
}

variable "node_pool_name" {
  type        = string
  description = "The name of the node pool"
}

variable "node_count" {
  type        = number
  description = "The number of nodes in the node pool"
}

variable "preemptible" {
  type        = bool
  description = "Whether the nodes are preemptible"
}

variable "machine_type" {
  type        = string
  description = "The machine type of the nodes"
}

variable "disk_size_gb" {
  type        = number
  description = "The size of the disk for the nodes"
}

variable "oauth_scopes" {
  type        = list(string)
  description = "The OAuth scopes for the nodes"
}