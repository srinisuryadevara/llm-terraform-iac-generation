variable "gcp_network_name" {
  type = string
}

variable "allowed_ip_range" {
  type = string
}

resource "google_compute_network" "vpc_network" {
  name                    = var.gcp_network_name
  auto_create_subnetworks = false
}

resource "google_compute_firewall" "fw_access" {
  name    = "terraform-firewall"
  network = google_compute_network.vpc_network.name

  deny {
    protocol = "all"
  }

  allow {
    protocol = "tcp"
    ports    = ["443"]
    source_ranges = [var.allowed_ip_range]
  }
}