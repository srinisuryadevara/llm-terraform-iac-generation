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

  name               = var.name
  description        = var.description
  project            = var.project
  location           = var.location
  network            = var.network
  subnetwork         = var.subnetwork
  private_cluster_config {
    enable_private_nodes = true
    master_ipv4_cidr_block = var.master_ipv4_cidr_block
  }
  master_authorized_networks_config {
    cidr_blocks {
      cidr_block   = var.master_authorized_networks_cidr_block
      display_name = var.master_authorized_networks_display_name
    }
  }
  workload_identity_config {
    workload_pool = var.workload_pool
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

variable "project" {
  type = string
}

variable "region" {
  type = string
}

variable "name" {
  type = string
}

variable "description" {
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

variable "master_ipv4_cidr_block" {
  type = string
}

variable "master_authorized_networks_cidr_block" {
  type = string
}

variable "master_authorized_networks_display_name" {
  type = string
}

variable "workload_pool" {
  type = string
}

variable "gke_node_machine_type" {
  type = string
}