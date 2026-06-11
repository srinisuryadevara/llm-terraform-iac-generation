provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_container_cluster" "primary" {
  name               = "primary-cluster"
  location           = var.region
  initial_node_count = 1

  network_policy {
    enabled = true
  }

  ip_allocation_policy {
    cluster_secondary_range_name  = "pod-range"
    services_secondary_range_name = "service-range"
  }
}

resource "google_container_node_pool" "primary" {
  name       = "primary-node-pool"
  cluster    = google_container_cluster.primary.name
  location   = var.region
  node_count = 1

  node_config {
    preemptible  = true
    machine_type = "e2-medium"
    oauth_scopes = [
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]
  }
}

resource "google_compute_network" "primary" {
  name                    = "primary-network"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "primary" {
  name          = "primary-subnetwork"
  ip_cidr_range = "10.0.0.0/16"
  region        = var.region
  network       = google_compute_network.primary.id
}

resource "google_compute_subnetwork" "pod_range" {
  name          = "pod-range"
  ip_cidr_range = "10.1.0.0/16"
  region        = var.region
  network       = google_compute_network.primary.id
}

resource "google_compute_subnetwork" "service_range" {
  name          = "service-range"
  ip_cidr_range = "10.2.0.0/16"
  region        = var.region
  network       = google_compute_network.primary.id
}