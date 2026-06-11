variable "project_id" {
  type        = string
  description = "The ID of the project"
}

variable "network_name" {
  type        = string
  description = "The name of the network"
}

variable "allowed_cidr" {
  type        = string
  description = "The allowed CIDR range for SSH"
}

resource "google_compute_network" "gcp-network" {
  name                    = var.network_name
  project                 = var.project_id
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "gcp-subnetwork" {
  name          = "${var.network_name}-subnetwork"
  ip_cidr_range = "10.0.0.0/16"
  network       = google_compute_network.gcp-network.id
  project       = var.project_id
}

resource "google_compute_firewall" "gcp-allow-ssh" {
  name    = "${google_compute_network.gcp-network.name}-gcp-allow-ssh"
  network = google_compute_network.gcp-network.name
  project = var.project_id

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = [
    var.allowed_cidr
  ]
}