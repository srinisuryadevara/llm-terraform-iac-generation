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
  type        = string
  description = "GCP project ID"
}

variable "region" {
  type        = string
  description = "GCP region"
}

variable "machine_type" {
  type        = string
  description = "GCP machine type"
}

variable "prefix" {
  type        = string
  description = "Prefix for resource names"
}

variable "subnet_prefix" {
  type        = string
  description = "Subnet IP prefix"
}

resource "google_compute_network" "instance" {
  name                    = "${var.prefix}-vpc-${var.region}"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "instance" {
  name          = "${var.prefix}-subnet"
  region        = var.region
  network       = google_compute_network.instance.self_link
  ip_cidr_range = var.subnet_prefix
}

resource "google_compute_firewall" "instance" {
  name    = "${var.prefix}-default-allow-ssh-http"
  network = google_compute_network.instance.self_link

  allow {
    protocol = "tcp"
    ports    = ["22", "80"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["instance"]
}

resource "tls_private_key" "ssh-key" {
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
    subnetwork = google_compute_subnetwork.instance.self_link
    access_config {
    }
  }

  metadata = {
    ssh-keys = "ubuntu:${chomp(tls_private_key.ssh-key.public_key_openssh)} terraform"
  }

  tags = ["instance"]
}