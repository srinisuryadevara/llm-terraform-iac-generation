variable "gcp_network_name" {
  type = string
}

variable "gcp_project_id" {
  type = string
}

variable "ssh_allowed_cidr" {
  type = string
}

resource "google_compute_network" "gcp-network" {
  name                    = var.gcp_network_name
  project                 = var.gcp_project_id
  auto_create_subnetworks = false
}

resource "google_compute_firewall" "gcp-allow-ssh" {
  name    = "${google_compute_network.gcp-network.name}-gcp-allow-ssh"
  network = google_compute_network.gcp-network.name
  project = var.gcp_project_id

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = [
    var.ssh_allowed_cidr
  ]
}