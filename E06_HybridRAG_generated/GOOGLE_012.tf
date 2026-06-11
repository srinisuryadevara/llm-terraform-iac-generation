terraform {
  required_version = ">= 0.12.8"
}

provider "google" {
  credentials = "${file("account.json")}"
  version     = "~> 2.9.0"
  project     = var.project
  region      = var.region

  scopes = [
    "https://www.googleapis.com/auth/compute",
    "https://www.googleapis.com/auth/cloud-platform",
    "https://www.googleapis.com/auth/ndev.clouddns.readwrite",
    "https://www.googleapis.com/auth/devstorage.full_control",
    "https://www.googleapis.com/auth/userinfo.email",
  ]
}

provider "google-beta" {
  credentials = "${file("account.json")}"
  version     = "~> 2.9.0"
  project     = var.project
  region      = var.region

  scopes = [
    "https://www.googleapis.com/auth/compute",
    "https://www.googleapis.com/auth/cloud-platform",
    "https://www.googleapis.com/auth/ndev.clouddns.readwrite",
    "https://www.googleapis.com/auth/devstorage.full_control",
    "https://www.googleapis.com/auth/userinfo.email",
  ]
}

data "google_client_config" "client" {}

resource "google_container_cluster" "cluster" {
  provider = google-beta

  name        = var.name
  description = var.description

  project    = var.project
  location   = var.location
  network    = var.network
  subnetwork = var.subnetwork

  network_policy {
    enabled = true
  }
}

resource "google_container_node_pool" "node_pool" {
  provider = google-beta

  name       = var.node_pool_name
  cluster    = google_container_cluster.cluster.name
  location   = var.location
  node_count = var.node_count

  node_config {
    oauth_scopes = [
      "https://www.googleapis.com/auth/compute",
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]

    disk_size_gb = var.disk_size_gb
    machine_type = var.machine_type
    tags         = ["gke-node"]
  }
}