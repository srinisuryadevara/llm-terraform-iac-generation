variable "project" {
  type        = string
  description = "GCP project ID"
}

variable "region" {
  type        = string
  description = "GCP region"
}

variable "ssh_cidr_range" {
  type        = string
  description = "CIDR range for SSH access"
}

variable "network_name" {
  type        = string
  description = "Name of the network"
}

provider "google" {
  project = var.project
  region  = var.region
}

resource "google_compute_network" "example" {
  name                    = var.network_name
  auto_create_subnetworks = false
  mtu                     = 1460
  routing_mode            = "REGIONAL"
}

resource "google_compute_subnetwork" "example" {
  name          = "${var.network_name}-subnet"
  ip_cidr_range = "10.0.0.0/16"
  network       = google_compute_network.example.id
  region        = var.region
}

resource "google_compute_firewall" "ssh" {
  name    = "allow-ssh"
  network = google_compute_network.example.id

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = [var.ssh_cidr_range]

  target_tags = ["ssh-access"]

  depends_on = [google_compute_network.example]
}

resource "google_compute_instance" "example" {
  name         = "example-instance"
  machine_type = "f1-micro"
  zone         = "${var.region}-a"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  network_interface {
    network = google_compute_network.example.id
    subnetwork = google_compute_subnetwork.example.id
  }

  tags = ["ssh-access"]

  depends_on = [google_compute_firewall.ssh]
}