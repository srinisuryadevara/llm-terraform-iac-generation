provider "google" {
  project = var.project_id
  region  = var.region
}

variable "project_id" {
  type        = string
  description = "The ID of the project"
}

variable "region" {
  type        = string
  description = "The region to create resources in"
}

variable "allowed_cidr" {
  type        = string
  description = "The allowed CIDR range for SSH access"
}

resource "google_compute_firewall" "ssh_firewall" {
  name    = "ssh-restricted-firewall"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = [var.allowed_cidr]

  target_tags = ["ssh-restricted"]
}