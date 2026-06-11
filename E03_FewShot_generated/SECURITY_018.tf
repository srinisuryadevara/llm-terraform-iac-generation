variable "allowed_ip_range" {
  type        = string
  description = "Named IP range allowed to access port 443"
}

variable "network_name" {
  type        = string
  description = "Name of the network to apply the firewall rule"
}

variable "project_id" {
  type        = string
  description = "ID of the project to create the firewall rule"
}

resource "google_compute_firewall" "allow_https" {
  name    = "allow-https-from-${var.allowed_ip_range}"
  network = var.network_name

  allow {
    protocol = "tcp"
    ports    = ["443"]
  }

  source_ranges = [var.allowed_ip_range]

  project = var.project_id
}

resource "google_compute_firewall" "deny_all_ingress" {
  name    = "deny-all-ingress"
  network = var.network_name

  deny {
    protocol = "all"
  }

  priority = 65534

  project = var.project_id
}