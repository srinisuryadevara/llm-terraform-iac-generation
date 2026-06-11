# Configure the Google Cloud provider
provider "google" {
  project     = var.gcp_project
  region      = var.gcp_region
  credentials = var.gcp_credentials_key_file
}

# Create google network
resource "google_compute_network" "default" {
  name                    = "restricted-ssh-network"
}

# Allow SSH for a specific CIDR range
resource "google_compute_firewall" "gcp-allow-ssh" {
  name    = "${google_compute_network.default.name}-gcp-allow-ssh"
  network = google_compute_network.default.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = [
    var.restricted_cidr
  ]
}

variable "gcp_project" {
  type        = string
  sensitive   = true
}

variable "gcp_region" {
  type        = string
  sensitive   = true
}

variable "gcp_credentials_key_file" {
  type        = string
  sensitive   = true
}

variable "restricted_cidr" {
  type        = string
  default     = "192.168.1.0/24"
}