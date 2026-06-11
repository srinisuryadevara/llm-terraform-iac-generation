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
}

resource "google_memorystore_redis_instance" "redis" {
  name           = var.redis_instance_name
  tier           = var.redis_instance_tier
  memory_size_gb = 1

  redis_version = "REDIS_6_X"

  depends_on = [google_compute_network.vpc, google_compute_subnetwork.subnet]
}

resource "google_compute_firewall" "redis" {
  name    = "redis-firewall"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["6379"]
  }

  target_tags = ["redis"]
}

resource "google_compute_address" "redis" {
  name = "redis-address"
}

resource "google_memorystore_redis_instance" "redis_instance" {
  name           = var.redis_instance_name
  tier           = var.redis_instance_tier
  memory_size_gb = 1

  authorized_network = google_compute_network.vpc.id
  redis_version      = "REDIS_6_X"

  depends_on = [google_compute_network.vpc, google_compute_subnetwork.subnet]
}