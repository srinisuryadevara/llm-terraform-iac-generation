provider "google" {
  project = var.project_id
  region  = var.region
}

variable "project_id" {
  type = string
}

variable "region" {
  type = string
}

variable "cluster_name" {
  type = string
}

variable "network_name" {
  type = string
}

variable "subnet_name" {
  type = string
}

resource "google_container_cluster" "private_cluster" {
  name               = var.cluster_name
  location           = var.region
  project            = var.project_id
  network            = google_compute_network.private_network.id
  subnetwork         = google_compute_subnetwork.private_subnet.id
  private_cluster_config {
    enable_private_nodes = true
    master_ipv4_cidr_block = "10.0.0.0/28"
  }
  master_authorized_networks_config {
    cidr_blocks {
      cidr_block = "10.0.1.0/24"
      display_name = "Authorized Network"
    }
  }
  workload_identity_config {
    workload_pool = "projects/${var.project_id}/locations/global/workloadIdentityPools/${var.project_id}"
  }
  remove_default_node_pool = true
  initial_node_count       = 1
}

resource "google_compute_network" "private_network" {
  name                    = var.network_name
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "private_subnet" {
  name          = var.subnet_name
  ip_cidr_range = "10.0.2.0/24"
  network       = google_compute_network.private_network.id
  region        = var.region
}

resource "google_service_account" "gke_service_account" {
  account_id = "gke-service-account"
}

resource "google_project_iam_binding" "gke_service_account_binding" {
  project = var.project_id
  role    = "roles/container.developer"
  members = [
    "serviceAccount:${google_service_account.gke_service_account.email}",
  ]
}

resource "google_iam_workload_identity_pool" "gke_workload_identity_pool" {
  provider            = google
  project              = var.project_id
  workload_identity_pool_id = var.project_id
}

resource "google_iam_workload_identity_pool_provider" "gke_workload_identity_pool_provider" {
  provider            = google
  project             = var.project_id
  workload_identity_pool_id = google_iam_workload_identity_pool.gke_workload_identity_pool.workload_identity_pool_id
  provider_id         = "gke-${var.project_id}"
}