resource "google_compute_firewall" "restricted_ingress" {
  name    = "restricted-ingress-firewall"
  network = google_compute_network.vpc_network.name

  deny {
    protocol = "all"
  }

  allow {
    protocol = "tcp"
    ports    = ["443"]
  }

  source_ranges = [var.restricted_ip_range]
}