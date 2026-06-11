terraform {
  required_version = ">= 0.12.7"
}

provider "google" {
  version = "~> 4.0.0"
  project = var.project
  region  = var.region
}

provider "google-beta" {
  version = "~> 4.0.0"
  project = var.project
  region  = var.region
}

resource "google_container_cluster" "cluster" {
  provider = google-beta

  name        = var.name
  description = var.description

  project    = var.project
  location   = var.location
  network    = var.network
  subnetwork = var.subnetwork

  # We can't create a cluster with no node pool defined, but we want to manage all
  # node pools. So we create the smallest possible default node pool and immediately
  # delete it. This is a user-friendly way of creating a "no default node pool" cluster.
  remove_default_node_pool = true
  initial_node_count       = 1
}

resource "google_container_node_pool" "node_pool" {
  provider = google-beta

  name       = var.node_pool_name
  cluster    = google_container_cluster.cluster.name
  location   = var.location
  project    = var.project
  node_count = var.node_count

  node_config {
    preemptible  = var.preemptible
    machine_type = var.machine_type
    disk_size_gb = var.disk_size_gb
    oauth_scopes = var.oauth_scopes
  }
}

resource "google_container_cluster_network_policy" "network_policy" {
  provider = google-beta

  name                = var.network_policy_name
  cluster             = google_container_cluster.cluster.name
  project             = var.project
  location            = var.location
  default_policy_type = var.default_policy_type
}