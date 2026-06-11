provider "google" {
  project = var.project_id
  region  = var.region
}

variable "project_id" {
  type = string
}

variable "region" {
  type = string
}

variable "instance_name" {
  type = string
}

variable "instance_zone" {
  type = string
}

variable "machine_type" {
  type = string
}

variable "image_family" {
  type = string
}

variable "network_name" {
  type = string
}

variable "firewall_tag" {
  type = string
}

resource "google_compute_network" "default" {
  name                    = var.network_name
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "default" {
  name          = "${var.network_name}-subnet"
  ip_cidr_range = "10.0.0.0/16"
  network       = google_compute_network.default.id
  region        = var.region
}

resource "google_compute_firewall" "default" {
  name    = var.firewall_tag
  network = google_compute_network.default.id

  allow {
    protocol = "tcp"
    ports     = ["22", "80", "443"]
  }

  target_tags = [var.firewall_tag]
}

resource "google_compute_instance" "default" {
  name         = var.instance_name
  machine_type = var.machine_type
  zone         = var.instance_zone

  boot_disk {
    initialize_params {
      image = "projects/debian-cloud/global/images/family/${var.image_family}"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.default.id
    access_config {
    }
  }

  tags = [var.firewall_tag]
}