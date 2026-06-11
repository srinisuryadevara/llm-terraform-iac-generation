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

variable "ip_range_name" {
  type = string
}

variable "ip_range_cidr" {
  type = string
}

resource "google_compute_firewall" "allow_https" {
  name    = "allow-https-${var.ip_range_name}"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["443"]
  }

  source_ranges = [var.ip_range_cidr]

  target_tags = ["https-server"]
}