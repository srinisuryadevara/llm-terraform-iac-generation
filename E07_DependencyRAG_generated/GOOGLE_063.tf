variable "project" {
  type        = string
  description = "The ID of the project to create the resources in"
}

variable "region" {
  type        = string
  description = "The region to create the resources in"
}

variable "environment" {
  type        = string
  description = "The environment to create the resources in"
}

variable "network_name" {
  type        = string
  description = "The name of the network to create"
}

variable "subnet_name" {
  type        = string
  description = "The name of the subnet to create"
}

variable "cluster_name" {
  type        = string
  description = "The name of the GKE cluster to create"
}

variable "node_pool_name" {
  type        = string
  description = "The name of the node pool to create"
}

variable "node_count" {
  type        = number
  description = "The number of nodes to create in the node pool"
}

provider "google" {
  project = var.project
  region  = var.region
}

provider "google-beta" {
  project = var.project
  region  = var.region
}

data "google_container_engine_versions" "gke_version" {
  location = var.region
  version_prefix = "1.27."
}

data "google_client_config" "default" {
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
  name               = var.cluster_name
  location           = var.region
  initial_node_count = var.node_count

  network    = google_compute_network.vpc.name
  subnetwork = google_compute_subnetwork.subnet.name

  remove_default_node_pool = true
  enable_network_policy    = true
}

resource "google_container_node_pool" "node_pool" {
  name       = var.node_pool_name
  location   = var.region
  cluster    = google_container_cluster.gke_cluster.name
  version    = data.google_container_engine_versions.gke_version.release_channel_latest_version["STABLE"]
  node_count = var.node_count

  node_config {
    preemptible  = true
    machine_type = "n1-standard-1"
    disk_size_gb = 50
    oauth_scopes = [
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]
  }
}