variable "allowed_ip_range" {
  type = string
}

resource "google_compute_firewall" "allow_https" {
  name    = "allow-https"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["443"]
  }

  source_ranges = [var.allowed_ip_range]

  deny {
    protocol = "all"
  }

  target_tags = ["allow-https"]
}