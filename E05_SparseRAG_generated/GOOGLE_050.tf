terraform {
  required_version = ">= 0.12.7"
}

provider "google" {
  version = "~> 4.0.0"
  project = var.project
  region  = var.region
}

provider "google-beta" {
  version = "~> 4.0.0"
  project = var.project
  region  = var.region
}

resource "google_container_cluster" "cluster" {
  provider = google-beta

  name        = var.name
  description = var.description

  project    = var.project
  location   = var.location
  network    = var.network
  subnetwork = var.subnetwork

  # Enable network policy
  network_policy {
    enabled = true
  }
}

resource "google_container_node_pool" "node_pool" {
  provider = google-beta

  name       = var.node_pool_name
  cluster    = google_container_cluster.cluster.name
  location   = var.location
  project    = var.project
  node_count = var.node_count

  node_config {
    preemptible  = var.preemptible
    machine_type = var.machine_type
    disk_size_gb = var.disk_size_gb
    oauth_scopes = var.oauth_scopes
  }
}

variable "project" {
  type        = string
  description = "The ID of the project to create the cluster in"
}

variable "region" {
  type        = string
  description = "The region to create the cluster in"
}

variable "location" {
  type        = string
  description = "The location to create the cluster in"
}

variable "name" {
  type        = string
  description = "The name of the cluster"
}

variable "description" {
  type        = string
  description = "The description of the cluster"
}

variable "network" {
  type        = string
  description = "The network to create the cluster in"
}

variable "subnetwork" {
  type        = string
  description = "The subnetwork to create the cluster in"
}

variable "node_pool_name" {
  type        = string
  description = "The name of the node pool"
}

variable "node_count" {
  type        = number
  description = "The number of nodes in the node pool"
}

variable "preemptible" {
  type        = bool
  description = "Whether the nodes in the node pool are preemptible"
}

variable "machine_type" {
  type        = string
  description = "The machine type of the nodes in the node pool"
}

variable "disk_size_gb" {
  type        = number
  description = "The disk size of the nodes in the node pool"
}

variable "oauth_scopes" {
  type        = list(string)
  description = "The OAuth scopes of the nodes in the node pool"
}