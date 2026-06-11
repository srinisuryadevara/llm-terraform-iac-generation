provider "google" {
  project = var.project_id
  region  = var.region
}

variable "project_id" {
  type        = string
  sensitive   = true
}

variable "region" {
  type        = string
  sensitive   = true
}

variable "instance_name" {
  type        = string
  default     = "example-instance"
}

variable "instance_type" {
  type        = string
  default     = "f1-micro"
}

variable "network_name" {
  type        = string
  default     = "example-network"
}

variable "firewall_tag" {
  type        = string
  default     = "example-firewall-tag"
}

resource "google_compute_network" "example" {
  name                    = var.network_name
  auto_create_subnetworks = false
  labels = {
    environment = "example"
    managed_by  = "terraform"
  }
}

resource "google_compute_subnetwork" "example" {
  name          = "example-subnetwork"
  ip_cidr_range = "10.0.0.0/16"
  network       = google_compute_network.example.id
  region        = var.region
  labels = {
    environment = "example"
    managed_by  = "terraform"
  }
}

resource "google_compute_firewall" "example" {
  name    = "example-firewall"
  network = google_compute_network.example.id

  allow {
    protocol = "tcp"
    ports    = ["22", "80", "443"]
  }

  target_tags = [var.firewall_tag]
  labels = {
    environment = "example"
    managed_by  = "terraform"
  }
}

resource "google_compute_instance" "example" {
  name         = var.instance_name
  machine_type = var.instance_type
  zone         = "${var.region}-a"
  labels = {
    environment = "example"
    managed_by  = "terraform"
  }

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.example.id
    access_config {
    }
  }

  tags = [var.firewall_tag]
}

output "instance_id" {
  value       = google_compute_instance.example.id
  description = "ID of the Compute Engine instance"
}

output "instance_name" {
  value       = google_compute_instance.example.name
  description = "Name of the Compute Engine instance"
}

output "instance_zone" {
  value       = google_compute_instance.example.zone
  description = "Zone of the Compute Engine instance"
}

output "instance_network" {
  value       = google_compute_instance.example.network_interface[0].network
  description = "Network of the Compute Engine instance"
}

output "instance_subnetwork" {
  value       = google_compute_instance.example.network_interface[0].subnetwork
  description = "Subnetwork of the Compute Engine instance"
}

output "instance_external_ip" {
  value       = google_compute_instance.example.network_interface[0].access_config[0].nat_ip
  description = "External IP address of the Compute Engine instance"
}

output "firewall_id" {
  value       = google_compute_firewall.example.id
  description = "ID of the firewall rule"
}

output "firewall_name" {
  value       = google_compute_firewall.example.name
  description = "Name of the firewall rule"
}

output "network_id" {
  value       = google_compute_network.example.id
  description = "ID of the network"
}

output "network_name" {
  value       = google_compute_network.example.name
  description = "Name of the network"
}

output "subnetwork_id" {
  value       = google_compute_subnetwork.example.id
  description = "ID of the subnetwork"
}

output "subnetwork_name" {
  value       = google_compute_subnetwork.example.name
  description = "Name of the subnetwork"
}