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

variable "allowed_cidr_range" {
  type        = string
  default     = "192.168.1.0/24"
}

resource "google_compute_firewall" "ssh_restricted" {
  name    = "ssh-restricted"
  network = "default"
  labels = {
    environment = "production"
    purpose     = "SSH restriction"
  }

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = [var.allowed_cidr_range]
}

output "firewall_id" {
  value       = google_compute_firewall.ssh_restricted.id
  description = "ID of the SSH restricted firewall rule"
}

output "firewall_name" {
  value       = google_compute_firewall.ssh_restricted.name
  description = "Name of the SSH restricted firewall rule"
}

output "firewall_network" {
  value       = google_compute_firewall.ssh_restricted.network
  description = "Network of the SSH restricted firewall rule"
}