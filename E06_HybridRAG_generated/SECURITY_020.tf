# Configure the Google Cloud provider
provider "google" {
  project     = var.gcp_project
  region      = var.gcp_region
  credentials = var.gcp_credentials_key_file
}

# Create google network
resource "google_compute_network" "gcp-network" {
  name                    = var.gcp_network_name
}

# Allow SSH for a specific CIDR range
resource "google_compute_firewall" "gcp-allow-ssh" {
  name    = "${google_compute_network.gcp-network.name}-gcp-allow-ssh"
  network = google_compute_network.gcp-network.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = [
    var.allowed_ssh_cidr
  ]
}

# Allow PING testing
resource "google_compute_firewall" "gcp-allow-icmp" {
  name    = "${google_compute_network.gcp-network.name}-gcp-allow-icmp"
  network = google_compute_network.gcp-network.name

  allow {
    protocol = "icmp"
  }

  source_ranges = [
    var.allowed_ping_cidr
  ]
}