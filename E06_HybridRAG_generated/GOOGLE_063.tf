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

resource "google_container_cluster" "primary" {
  provider = google-beta

  name               = "ca-gke-${terraform.workspace}-cluster"
  zone               = "${var.region}-a"
  initial_node_count = "${var.gke_num_nodes[terraform.workspace]}"

  additional_zones = [
    "${var.region}-b",
  ]

  network_policy {
    enabled = true
  }

  master_auth {
    username = var.gke_master_user
    password = var.gke_master_pass
  }

  node_config {
    oauth_scopes = [
      "https://www.googleapis.com/auth/compute",
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]

    disk_size_gb = 10
    machine_type = var.gke_node_machine_type
    tags         = ["gke-node"]
  }
}

resource "google_container_node_pool" "primary" {
  provider = google-beta

  name       = "ca-gke-${terraform.workspace}-node-pool"
  cluster    = google_container_cluster.primary.name
  zone       = "${var.region}-a"
  node_count = var.gke_num_nodes[terraform.workspace]

  node_config {
    oauth_scopes = [
      "https://www.googleapis.com/auth/compute",
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]

    disk_size_gb = 10
    machine_type = var.gke_node_machine_type
    tags         = ["gke-node"]
  }
}

variable "project" {
  type = string
}

variable "region" {
  type = string
}

variable "gke_num_nodes" {
  type = map(string)
}

variable "gke_master_user" {
  type = string
}

variable "gke_master_pass" {
  type = string
}

variable "gke_node_machine_type" {
  type = string
}