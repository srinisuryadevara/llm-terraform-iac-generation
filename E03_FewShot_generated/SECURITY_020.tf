variable "project_id" {
  type        = string
  sensitive   = true
}

variable "allowed_cidr" {
  type        = string
  default     = "192.168.1.0/24"
}

variable "network_name" {
  type        = string
  default     = "default"
}

resource "google_compute_firewall" "ssh_restricted" {
  name    = "ssh-restricted"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = [var.allowed_cidr]

  target_tags = ["ssh-restricted"]
}

resource "google_compute_network" "vpc" {
  name                    = var.network_name
  auto_create_subnetworks = false
}