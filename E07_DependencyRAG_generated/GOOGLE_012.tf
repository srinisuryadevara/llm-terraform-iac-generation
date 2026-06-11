variable "project" {
  type = string
}

variable "region" {
  type = string
}

variable "environment" {
  type = string
}

variable "credentials" {
  type = string
}

provider "google" {
  project = var.project
  region  = var.region
  credentials = var.credentials
}

provider "google-beta" {
  project = var.project
  region  = var.region
  credentials = var.credentials
}

data "google_client_config" "default" {
}

data "google_container_engine_versions" "gke_version" {
  location = var.region
  version_prefix = "1.27."
}

resource "google_compute_network" "vpc" {
  name                    = "gke-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "subnet" {
  name          = "gke-subnet"
  ip_cidr_range = "10.0.0.0/16"
  network       = google_compute_network.vpc.id
  region        = var.region
}

resource "google_container_cluster" "gke_cluster" {
  provider = google-beta
  name     = "gke-cluster"
  location = var.region

  remove_default_node_pool = true
  initial_node_count       = 1

  network    = google_compute_network.vpc.name
  subnetwork = google_compute_subnetwork.subnet.name

  network_policy {
    enabled = true
  }
}

resource "google_container_node_pool" "gke_node_pool" {
  name       = google_container_cluster.gke_cluster.name
  location   = var.region
  cluster    = google_container_cluster.gke_cluster.name
  version    = data.google_container_engine_versions.gke_version.release_channel_latest_version["STABLE"]

  node_config {
    preemptible  = true
    machine_type = "n1-standard-1"
    disk_size_gb = 50
    oauth_scopes = [
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]
  }
}