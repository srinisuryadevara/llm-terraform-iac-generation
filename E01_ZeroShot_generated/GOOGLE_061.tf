provider "google" {
  project = var.project_id
  region  = var.region
}

variable "project_id" {
  type = string
}

variable "region" {
  type = string
}

variable "vpc_name" {
  type = string
}

variable "subnet_name" {
  type = string
}

variable "redis_instance_name" {
  type = string
}

variable "redis_instance_tier" {
  type = string
}

resource "google_compute_network" "vpc" {
  name                    = var.vpc_name
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "subnet" {
  name          = var.subnet_name
  ip_cidr_range = "10.0.0.0/16"
  network       = google_compute_network.vpc.id
  region        = var.region
}

resource "google_redis_instance" "redis" {
  name           = var.redis_instance_name
  tier           = var.redis_instance_tier
  memory_size_gb = 1

  redis_version = "6.x"

  authorized_network = google_compute_network.vpc.id
}

resource "google_compute_firewall" "redis" {
  name    = "redis-firewall"
  network = google_compute_network.vpc.id

  allow {
    protocol = "tcp"
    ports    = ["6379"]
  }

  target_tags = ["redis"]
}