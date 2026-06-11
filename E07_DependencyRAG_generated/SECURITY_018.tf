variable "ip_range" {
  type = string
}

variable "network_name" {
  type = string
}

resource "google_compute_network" "vpc_network" {
  name                    = var.network_name
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
    source_ranges = [var.ip_range]
  }
}