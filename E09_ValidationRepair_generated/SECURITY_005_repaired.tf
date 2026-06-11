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
  default     = "192.168.1.0/24"
}

resource "google_compute_firewall" "ssh-restricted" {
  name    = "ssh-restricted"
  network = "default"
  labels = {
    environment = "production"
    purpose     = "ssh-restriction"
  }

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = [var.allowed_cidr]
}

output "firewall_id" {
  value       = google_compute_firewall.ssh-restricted.id
  description = "ID of the SSH restricted firewall rule"
}

output "firewall_name" {
  value       = google_compute_firewall.ssh-restricted.name
  description = "Name of the SSH restricted firewall rule"
}