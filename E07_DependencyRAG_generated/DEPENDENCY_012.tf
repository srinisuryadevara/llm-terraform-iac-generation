variable "project" {
  type        = string
  description = "The ID of the project to apply any resources to"
}

variable "region" {
  type        = string
  description = "The region to apply any resources to"
}

variable "environment" {
  type        = string
  description = "The environment to apply any resources to"
}

variable "vpc_name" {
  type        = string
  description = "The name of the VPC to apply any resources to"
}

variable "subnet_name" {
  type        = string
  description = "The name of the subnet to apply any resources to"
}

data "google_compute_zones" "available_zones" {
  project = var.project
  region  = var.region
}

resource "google_compute_network" "vpc" {
  name                    = var.vpc_name
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "subnet" {
  name          = var.subnet_name
  ip_cidr_range = "10.2.0.0/16"
  region        = var.region
  network       = google_compute_network.vpc.id
}

resource "google_container_cluster" "workload_cluster" {
  name               = "terragoat-${var.environment}-cluster"
  logging_service    = "none"
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
}

resource "google_container_node_pool" "custom_node_pool" {
  cluster  = google_container_cluster.workload_cluster.name
  location = var.region

  node_config {
    image_type = "Ubuntu"
  }
}