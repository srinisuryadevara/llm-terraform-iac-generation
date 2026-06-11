variable "project" {
  type = string
}

variable "region" {
  type = string
}

variable "environment" {
  type = string
}

variable "network_name" {
  type = string
}

variable "subnet_name" {
  type = string
}

variable "node_pool_name" {
  type = string
}

variable "node_pool_image_type" {
  type = string
}

variable "node_pool_node_count" {
  type = number
}

variable "node_pool_version" {
  type = string
}

provider "google" {
  project = var.project
  region  = var.region
}

provider "google-beta" {
  project = var.project
  region  = var.region
}

data "google_compute_zones" "available_zones" {
  project = var.project
  region  = var.region
}

data "google_container_engine_versions" "gke_version" {
  location = var.region
  version_prefix = var.node_pool_version
}

resource "google_compute_network" "vpc" {
  name                    = var.network_name
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "subnet" {
  name          = var.subnet_name
  ip_cidr_range = "10.0.0.0/16"
  network       = google_compute_network.vpc.id
  region        = var.region
}

resource "google_container_cluster" "gke_cluster" {
  provider = google-beta
  name               = "terragoat-${var.environment}-cluster"
  location           = var.region
  initial_node_count = 1

  enable_legacy_abac       = true
  monitoring_service       = "none"
  remove_default_node_pool = true
  network                  = google_compute_network.vpc.name
  subnetwork               = google_compute_subnetwork.subnet.name
  master_authorized_networks_config {
    cidr_blocks {
      cidr_block = "0.0.0.0/0"
    }
  }
  network_policy {
    enabled = true
  }
}

resource "google_container_node_pool" "gke_node_pool" {
  name       = var.node_pool_name
  location   = var.region
  cluster    = google_container_cluster.gke_cluster.name
  version    = data.google_container_engine_versions.gke_version.release_channel_latest_version["STABLE"]
  node_count = var.node_pool_node_count

  node_config {
    image_type = var.node_pool_image_type
  }
}