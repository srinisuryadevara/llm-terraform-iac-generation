terraform {
  required_version = ">= 0.12.8"
}

provider "google" {
  credentials = var.credentials
  version     = "~> 4.0.0"
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
  credentials = var.credentials
  version     = "~> 4.0.0"
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

  name               = var.cluster_name
  location           = var.location
  project            = var.project
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
    workload_metadata_config {
      node_metadata = "GKE_METADATA"
    }
  }
}

variable "credentials" {
  type        = string
  sensitive   = true
}

variable "project" {
  type        = string
}

variable "region" {
  type        = string
}

variable "location" {
  type        = string
}

variable "network" {
  type        = string
}

variable "subnetwork" {
  type        = string
}

variable "cluster_name" {
  type        = string
}

variable "master_ipv4_cidr_block" {
  type        = string
}

variable "master_authorized_networks_cidr_block" {
  type        = string
}

variable "master_authorized_networks_display_name" {
  type        = string
}

variable "workload_pool" {
  type        = string
}