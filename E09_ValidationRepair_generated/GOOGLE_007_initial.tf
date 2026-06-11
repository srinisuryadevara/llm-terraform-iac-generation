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
}

resource "google_compute_subnetwork" "example" {
  name          = "example-subnetwork"
  ip_cidr_range = "10.0.0.0/16"
  network       = google_compute_network.example.id
  region        = var.region
}

resource "google_compute_firewall" "example" {
  name    = "example-firewall"
  network = google_compute_network.example.id

  allow {
    protocol = "tcp"
    ports    = ["22", "80", "443"]
  }

  target_tags = [var.firewall_tag]
}

resource "google_compute_instance" "example" {
  name         = var.instance_name
  machine_type = var.instance_type
  zone         = "${var.region}-a"

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