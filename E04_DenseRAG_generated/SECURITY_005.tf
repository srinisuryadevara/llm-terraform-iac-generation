variable "gcp_network_name" {
  type = string
}

variable "allowed_cidr_range" {
  type = string
}

resource "google_compute_network" "gcp-network" {
  name                    = var.gcp_network_name
  auto_create_subnetworks = false
}

resource "google_compute_firewall" "gcp-allow-ssh" {
  name    = "${google_compute_network.gcp-network.name}-gcp-allow-ssh"
  network = google_compute_network.gcp-network.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = [
    var.allowed_cidr_range
  ]
}