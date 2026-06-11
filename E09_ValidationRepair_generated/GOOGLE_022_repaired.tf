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
  default     = "us-central1"
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
    project     = var.project_id
  }
}

resource "google_compute_subnetwork" "example" {
  name          = "${var.network_name}-subnetwork"
  ip_cidr_range = "10.0.0.0/16"
  network       = google_compute_network.example.id
  region        = var.region
  labels = {
    environment = "example"
    project     = var.project_id
  }
}

resource "google_compute_firewall" "example" {
  name    = "${var.firewall_tag}-firewall"
  network = google_compute_network.example.id

  allow {
    protocol = "tcp"
    ports    = ["22", "80", "443"]
  }

  target_tags = [var.firewall_tag]
  labels = {
    environment = "example"
    project     = var.project_id
  }
}

resource "google_compute_instance" "example" {
  name         = var.instance_name
  machine_type = var.instance_type
  zone         = "${var.region}-a"
  labels = {
    environment = "example"
    project     = var.project_id
  }

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.example.id
  }

  tags = [var.firewall_tag]
}

output "instance_id" {
  value       = google_compute_instance.example.id
  description = "The ID of the instance"
}

output "instance_name" {
  value       = google_compute_instance.example.name
  description = "The name of the instance"
}

output "instance_zone" {
  value       = google_compute_instance.example.zone
  description = "The zone of the instance"
}

output "instance_network" {
  value       = google_compute_instance.example.network_interface[0].network
  description = "The network of the instance"
}

output "instance_subnetwork" {
  value       = google_compute_instance.example.network_interface[0].subnetwork
  description = "The subnetwork of the instance"
}

output "firewall_id" {
  value       = google_compute_firewall.example.id
  description = "The ID of the firewall"
}

output "firewall_name" {
  value       = google_compute_firewall.example.name
  description = "The name of the firewall"
}

output "network_id" {
  value       = google_compute_network.example.id
  description = "The ID of the network"
}

output "network_name" {
  value       = google_compute_network.example.name
  description = "The name of the network"
}

output "subnetwork_id" {
  value       = google_compute_subnetwork.example.id
  description = "The ID of the subnetwork"
}

output "subnetwork_name" {
  value       = google_compute_subnetwork.example.name
  description = "The name of the subnetwork"
}