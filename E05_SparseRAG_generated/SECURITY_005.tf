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

# Create a firewall rule to restrict SSH access
resource "google_compute_firewall" "restricted_ssh" {
  name    = "restricted-ssh-rule"
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
}