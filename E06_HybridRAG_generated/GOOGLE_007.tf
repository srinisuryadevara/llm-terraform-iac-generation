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

variable "project" {
  type = string
}

variable "region" {
  type = string
}

variable "machine_type" {
  type = string
}

variable "prefix" {
  type = string
}

variable "subnet_prefix" {
  type = string
}

resource "google_compute_network" "instance_network" {
  name                    = "${var.prefix}-vpc-${var.region}"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "instance_subnetwork" {
  name          = "${var.prefix}-subnet"
  region        = var.region
  network       = google_compute_network.instance_network.self_link
  ip_cidr_range = var.subnet_prefix
}

resource "google_compute_firewall" "instance_firewall" {
  name    = "${var.prefix}-default-allow-ssh-http"
  network = google_compute_network.instance_network.self_link

  allow {
    protocol = "tcp"
    ports    = ["22", "80"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["http-server"]
}

resource "tls_private_key" "ssh_key" {
  algorithm = "ED25519"
}

resource "google_compute_instance" "instance" {
  name         = "${var.prefix}-instance"
  zone         = "${var.region}-b"
  machine_type = var.machine_type

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.instance_subnetwork.self_link
    access_config {
    }
  }

  metadata = {
    ssh-keys = "ubuntu:${chomp(tls_private_key.ssh_key.public_key_openssh)} terraform"
  }

  tags = ["http-server"]
}