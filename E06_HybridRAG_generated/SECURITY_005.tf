variable "gcp_project" {
  type = string
}

variable "gcp_region" {
  type = string
}

variable "gcp_credentials_key_file" {
  type = string
}

variable "ssh_allowed_cidr" {
  type = string
}

variable "gcp_network_name" {
  type = string
}

provider "google" {
  project     = var.gcp_project
  region      = var.gcp_region
  credentials = var.gcp_credentials_key_file
}

resource "google_compute_network" "gcp-network" {
  name                    = var.gcp_network_name
}

resource "google_compute_firewall" "gcp-allow-ssh" {
  name    = "${google_compute_network.gcp-network.name}-gcp-allow-ssh"
  network = google_compute_network.gcp-network.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = [
    var.ssh_allowed_cidr
  ]
}