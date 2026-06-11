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

variable "vpc_network_name" {
  type        = string
  description = "Name of the VPC network"
}

provider "google" {
  project = var.project
  region  = var.region
}

resource "google_compute_network" "vpc_network" {
  name                    = var.vpc_network_name
  auto_create_subnetworks = false
  mtu                     = 1460
  tags                    = ["vpc-network"]
}

resource "google_compute_subnetwork" "subnet" {
  name          = "subnet"
  ip_cidr_range = "10.0.0.0/16"
  network       = google_compute_network.vpc_network.id
  region        = var.region
  tags          = ["subnet"]
}

resource "google_compute_firewall" "ssh_firewall" {
  name    = "ssh-firewall"
  network = google_compute_network.vpc_network.name
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  source_ranges = [var.ssh_cidr_range]
  target_tags   = ["ssh-server"]
  description   = "Firewall rule for SSH access"
  tags          = ["firewall-rule"]
}