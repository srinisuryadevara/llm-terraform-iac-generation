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

variable "allowed_cidr" {
  type = string
}

resource "google_compute_firewall" "ssh_firewall" {
  name    = "ssh-firewall-rule"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = [var.allowed_cidr]

  target_tags = ["ssh-access"]
}