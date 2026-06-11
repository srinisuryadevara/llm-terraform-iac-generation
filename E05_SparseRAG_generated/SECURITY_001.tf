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

resource "google_container_cluster" "cluster" {
  provider = google-beta

  name        = var.name
  description = var.description

  project    = var.project
  location   = var.location
  network    = var.network
  subnetwork = var.subnetwork

  private_cluster_config {
    enable_private_nodes = true
    master_ipv4_cidr_block = var.master_ipv4_cidr_block
  }

  master_authorized_networks_config {
    cidr_blocks {
      cidr_block = var.cidr_block
      display_name = var.display_name
    }
  }

  workload_identity_config {
    workload_pool = var.workload_pool
  }

  remove_default_node_pool = true
}

resource "google_container_node_pool" "node_pool" {
  provider = google-beta

  name       = var.node_pool_name
  cluster    = google_container_cluster.cluster.name
  project    = var.project
  location   = var.location
  node_count = var.node_count

  node_config {
    preemptible  = var.preemptible
    machine_type = var.machine_type
    disk_size_gb = var.disk_size_gb
    oauth_scopes = var.oauth_scopes
  }
}

variable "credentials" {
  type = string
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

variable "cidr_block" {
  type = string
}

variable "display_name" {
  type = string
}

variable "workload_pool" {
  type = string
}

variable "node_pool_name" {
  type = string
}

variable "node_count" {
  type = number
}

variable "preemptible" {
  type = bool
}

variable "machine_type" {
  type = string
}

variable "disk_size_gb" {
  type = number
}

variable "oauth_scopes" {
  type = list(string)
}