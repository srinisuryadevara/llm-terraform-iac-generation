variable "project" {
  type        = string
  description = "GCP project ID"
}

variable "region" {
  type        = string
  description = "GCP region"
}

variable "ssh_source_cidr" {
  type        = string
  description = "CIDR for SSH access"
}

variable "instance_name" {
  type        = string
  description = "Name of the Compute instance"
}

variable "instance_type" {
  type        = string
  description = "Type of the Compute instance"
}

variable "instance_zone" {
  type        = string
  description = "Zone of the Compute instance"
}

variable "network_name" {
  type        = string
  description = "Name of the network"
}

variable "subnetwork_name" {
  type        = string
  description = "Name of the subnetwork"
}

provider "google" {
  project = var.project
  region  = var.region
}

resource "google_compute_network" "vpc" {
  name                    = var.network_name
  auto_create_subnetworks = false
  mtu                     = 1460
  tags                    = ["vpc", var.network_name]
}

resource "google_compute_subnetwork" "subnet" {
  name          = var.subnetwork_name
  ip_cidr_range = "10.0.0.0/16"
  network       = google_compute_network.vpc.id
  region        = var.region
  tags          = ["subnet", var.subnetwork_name]
}

resource "google_compute_instance" "vm" {
  name         = var.instance_name
  machine_type = var.instance_type
  zone         = var.instance_zone

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.subnet.id
  }

  metadata = {
    ssh-keys = "username:${file("~/.ssh/id_rsa.pub")}"
  }

  tags = ["vm", var.instance_name]
}

resource "google_compute_firewall" "ssh" {
  name    = "ssh-firewall"
  network = google_compute_network.vpc.id

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = [var.ssh_source_cidr]
  target_tags   = ["vm"]
}

resource "google_compute_firewall" "https" {
  name    = "https-firewall"
  network = google_compute_network.vpc.id

  allow {
    protocol = "tcp"
    ports    = ["443"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["vm"]
}

resource "google_compute_firewall" "http" {
  name    = "http-firewall"
  network = google_compute_network.vpc.id

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["vm"]
}