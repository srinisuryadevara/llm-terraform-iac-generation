provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_compute_network" "vpc" {
  name                    = var.vpc_name
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "subnet" {
  name          = var.subnet_name
  ip_cidr_range = var.subnet_cidr
  network       = google_compute_network.vpc.id
  region        = var.region
}

resource "google_memorystore_instance" "redis" {
  name           = var.redis_name
  tier           = var.redis_tier
  memory_size_gb = var.redis_memory_size

  depends_on = [google_compute_network.vpc]

  authorized_network = google_compute_network.vpc.id
}

resource "google_compute_firewall" "redis" {
  name    = var.firewall_name
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["6379"]
  }

  target_tags = ["redis"]
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

variable "subnet_cidr" {
  type = string
}

variable "redis_name" {
  type = string
}

variable "redis_tier" {
  type = string
}

variable "redis_memory_size" {
  type = number
}

variable "firewall_name" {
  type = string
}