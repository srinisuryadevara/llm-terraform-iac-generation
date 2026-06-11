terraform {
  required_version = ">= 0.12.8"
}

variable "project" {}
variable "region" {}
variable "gke_num_nodes" {
  type = map(string)
}
variable "gke_master_user" {}
variable "gke_master_pass" {}
variable "gke_node_machine_type" {}
variable "authorized_networks" {
  type = list(object({
    cidr_block   = string
    display_name = string
  }))
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
  name               = "ca-gke-${terraform.workspace}-cluster"
  location           = var.region
  initial_node_count = var.gke_num_nodes[terraform.workspace]

  private_cluster_config {
    enable_private_nodes = true
    master_ipv4_cidr_block = "10.0.0.0/28"
  }

  master_authorized_networks_config {
    dynamic "cidr_blocks" {
      for_each = var.authorized_networks
      content {
        cidr_block   = cidr_blocks.value.cidr_block
        display_name = cidr_blocks.value.display_name
      }
    }
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
    workload_metadata_config {
      mode = "GKE_METADATA"
    }
  }

  workload_identity_config {
    workload_pool = "projects/${var.project}/locations/global/workloadIdentityPools/default"
  }
}