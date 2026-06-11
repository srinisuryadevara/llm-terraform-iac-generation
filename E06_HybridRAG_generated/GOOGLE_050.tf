terraform {
  required_version = ">= 0.12.8"
}

variable "project" {
  type = string
}

variable "region" {
  type = string
}

variable "location" {
  type = string
}

variable "network" {
  type = string
}

variable "subnetwork" {
  type = string
}

variable "name" {
  type = string
}

variable "description" {
  type = string
}

variable "gke_num_nodes" {
  type = map(string)
}

variable "gke_master_user" {
  type = string
  sensitive = true
}

variable "gke_master_pass" {
  type = string
  sensitive = true
}

variable "gke_node_machine_type" {
  type = string
}

provider "google" {
  credentials = file("account.json")
  version = "~> 2.9.0"
  project = var.project
  region  = var.region

  scopes = [
    "https://www.googleapis.com/auth/compute",
    "https://www.googleapis.com/auth/cloud-platform",
    "https://www.googleapis.com/auth/ndev.clouddns.readwrite",
    "https://www.googleapis.com/auth/devstorage.full_control",
    "https://www.googleapis.com/auth/userinfo.email",
  ]
}

provider "google-beta" {
  credentials = file("account.json")
  version = "~> 2.9.0"
  project = var.project
  region  = var.region

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

  node_pool {
    name       = "default-pool"
    node_count = var.gke_num_nodes["default"]

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

  network_policy {
    enabled = true
  }
}

resource "google_container_node_pool" "additional_pool" {
  provider = google-beta

  name       = "additional-pool"
  cluster    = google_container_cluster.cluster.name
  node_count = var.gke_num_nodes["additional"]

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