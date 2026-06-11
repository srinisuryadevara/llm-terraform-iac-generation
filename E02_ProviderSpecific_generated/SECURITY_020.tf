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
  sensitive   = true
}

variable "allowed_cidr" {
  type        = string
  sensitive   = true
}

resource "google_compute_firewall" "ssh_restricted" {
  name    = "ssh-restricted"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = [var.allowed_cidr]
}