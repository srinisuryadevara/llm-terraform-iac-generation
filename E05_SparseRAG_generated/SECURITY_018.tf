variable "gcp_region" {
  type        = string
  description = "GCP region"
}

variable "gcp_network_name" {
  type        = string
  description = "GCP network name"
}

variable "allowed_ip_range" {
  type        = string
  description = "Allowed IP range for ingress"
}

resource "google_compute_network" "gcp-network" {
  name                    = var.gcp_network_name
  auto_create_subnetworks = false
}

resource "google_compute_firewall" "gcp-firewall" {
  name    = "gcp-firewall-${var.gcp_region}"
  network = google_compute_network.gcp-network.name

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["443"]
  }

  source_ranges = [var.allowed_ip_range]

  deny {
    protocol = "tcp"
    ports    = ["0-442", "444-65535"]
  }

  deny {
    protocol = "udp"
    ports    = ["0-65535"]
  }

  deny {
    protocol = "icmp"
    ports    = []
  }

  deny {
    protocol = "ipsec-ah"
    ports    = []
  }

  deny {
    protocol = "ipsec-esp"
    ports    = []
  }

  deny {
    protocol = "sctp"
    ports    = []
  }
}