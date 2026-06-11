terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "=3.68.0"
    }
  }
}

provider "google" {
  project = var.project
  region  = var.region
}

resource "google_compute_network" "gcp-network" {
  name                    = "${var.prefix}-vpc-${var.region}"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "gcp-subnetwork" {
  name          = "${var.prefix}-subnet"
  region        = var.region
  network       = google_compute_network.gcp-network.self_link
  ip_cidr_range = var.subnet_prefix
}

resource "google_compute_firewall" "gcp-allow-icmp" {
  name    = "${google_compute_network.gcp-network.name}-gcp-allow-icmp"
  network = google_compute_network.gcp-network.self_link

  allow {
    protocol = "icmp"
  }

  source_ranges = [
    "0.0.0.0/0"
  ]
}

resource "google_compute_firewall" "gcp-allow-ssh" {
  name    = "${google_compute_network.gcp-network.name}-gcp-allow-ssh"
  network = google_compute_network.gcp-network.self_link

  allow {
    protocol = "tcp"
    ports = ["22"]
  }

  source_ranges = [
    "0.0.0.0/0"
  ]
}

resource "google_compute_firewall" "gcp-allow-http" {
  name    = "${google_compute_network.gcp-network.name}-gcp-allow-http"
  network = google_compute_network.gcp-network.self_link

  allow {
    protocol = "tcp"
    ports = ["80"]
  }

  source_ranges = [
    "0.0.0.0/0"
  ]
}

resource "tls_private_key" "ssh-key" {
  algorithm = "ED25519"
}

resource "google_compute_instance" "gcp-instance" {
  name         = "${var.prefix}-gcp-instance"
  zone         = "${var.region}-b"
  machine_type = var.machine_type

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.gcp-subnetwork.self_link
    access_config {
    }
  }

  metadata = {
    ssh-keys = "ubuntu:${chomp(tls_private_key.ssh-key.public_key_openssh)} terraform"
  }

  tags = ["http-server"]
}