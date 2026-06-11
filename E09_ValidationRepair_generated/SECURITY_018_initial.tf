variable "allowed_ip_range" {
  type = string
}

resource "google_compute_firewall" "default" {
  name    = "block-all-ingress-except-443"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["443"]
  }

  deny {
    protocol = "all"
  }

  source_ranges = [var.allowed_ip_range]
}