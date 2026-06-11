provider "google" {
  project = var.project
  region  = var.region
}

variable "project" {
  type = string
}

variable "region" {
  type = string
}

variable "allowed_ip_range" {
  type = string
}

resource "google_compute_firewall" "allow_https" {
  name    = "allow-https"
  network = "default"
  tags    = ["allow-https"]

  allow {
    protocol = "tcp"
    ports    = ["443"]
  }

  source_ranges = [var.allowed_ip_range]

  target_tags = ["allow-https"]
}

resource "google_compute_network" "default" {
  name                    = "default"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "default" {
  name          = "default"
  ip_cidr_range = "10.0.0.0/16"
  network       = google_compute_network.default.id
}