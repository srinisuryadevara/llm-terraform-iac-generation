provider "google" {
  project = var.project_id
  region  = var.region
}

variable "project_id" {
  type        = string
  description = "GCP project ID"
}

variable "region" {
  type        = string
  description = "GCP region"
}

variable "cluster_name" {
  type        = string
  description = "GKE cluster name"
}

variable "network_name" {
  type        = string
  description = "GCP network name"
}

variable "subnetwork_name" {
  type        = string
  description = "GCP subnetwork name"
}

variable "authorized_networks" {
  type        = list(string)
  description = "List of authorized networks for GKE master"
}

resource "google_compute_network" "vpc" {
  name                    = var.network_name
  auto_create_subnetworks = false
  mtu                     = 1460
  tags                    = ["gke-cluster", "private-nodes"]
}

resource "google_compute_subnetwork" "subnetwork" {
  name          = var.subnetwork_name
  ip_cidr_range = "10.0.0.0/16"
  network       = google_compute_network.vpc.id
  region        = var.region
  tags          = ["gke-cluster", "private-nodes"]
}

resource "google_container_cluster" "primary" {
  name               = var.cluster_name
  location           = var.region
  project            = var.project_id
  network            = google_compute_network.vpc.id
  subnetwork         = google_compute_subnetwork.subnetwork.id
  private_cluster_config {
    enable_private_nodes = true
    master_ipv4_cidr_block = "10.0.1.0/28"
  }
  master_authorized_networks_config {
    cidr_blocks {
      cidr_block   = var.authorized_networks[0]
      display_name = "Authorized Network"
    }
  }
  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }
  enable_shielded_nodes = true
  enable_intranode_visibility = true
  tags = ["gke-cluster", "private-nodes"]
}

resource "google_service_account" "gke_sa" {
  account_id = "gke-sa"
  project    = var.project_id
}

resource "google_project_iam_binding" "gke_sa_binding" {
  project = var.project_id
  role    = "roles/container.developer"
  members = [
    "serviceAccount:${google_service_account.gke_sa.email}",
  ]
}

resource "google_kms_key_ring" "key_ring" {
  name     = "gke-key-ring"
  location = var.region
  project  = var.project_id
}

resource "google_kms_crypto_key" "crypto_key" {
  name     = "gke-crypto-key"
  key_ring = google_kms_key_ring.key_ring.id
}

resource "google_kms_key_ring_iam_binding" "key_ring_binding" {
  key_ring_id = google_kms_key_ring.key_ring.id
  role        = "roles/cloudkms.cryptoKeyEncryptorDecryptor"
  members     = [
    "serviceAccount:${google_service_account.gke_sa.email}",
  ]
}