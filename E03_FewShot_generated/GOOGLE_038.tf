provider "google" {
  project = var.project_id
  region  = var.region
}

variable "project_id" {
  type        = string
  sensitive   = true
}

variable "region" {
  type        = string
  default     = "us-central1"
}

variable "vpc_name" {
  type        = string
}

variable "subnet_name" {
  type        = string
}

variable "redis_instance_name" {
  type        = string
}

variable "redis_instance_tier" {
  type        = string
  default     = "STANDARD_HA"
}

variable "redis_instance_memory_size_gb" {
  type        = number
  default     = 1
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

resource "google_redis_instance" "redis" {
  name           = var.redis_instance_name
  tier           = var.redis_instance_tier
  memory_size_gb = var.redis_instance_memory_size_gb

  redis_version = "6.x"

  depends_on = [google_compute_network.vpc, google_compute_subnetwork.subnet]
}

resource "google_compute_firewall" "redis_firewall" {
  name    = "${var.redis_instance_name}-firewall"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["6379"]
  }

  target_tags = ["${var.redis_instance_name}-tag"]
}

resource "google_compute_network_peering" "redis_peering" {
  name         = "${var.redis_instance_name}-peering"
  network      = google_compute_network.vpc.id
  peer_network = google_redis_instance.redis.authorized_network
}