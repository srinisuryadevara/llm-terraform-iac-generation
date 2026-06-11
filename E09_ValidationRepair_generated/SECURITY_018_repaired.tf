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

  labels = {
    environment = "production"
    purpose     = "security"
  }
}

output "firewall_id" {
  value       = google_compute_firewall.default.id
  description = "ID of the created firewall"
}

output "firewall_name" {
  value       = google_compute_firewall.default.name
  description = "Name of the created firewall"
}

output "firewall_network" {
  value       = google_compute_firewall.default.network
  description = "Network of the created firewall"
}