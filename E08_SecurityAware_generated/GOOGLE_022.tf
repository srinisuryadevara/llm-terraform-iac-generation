provider "google" {
  project = var.project_id
  region  = var.region
}

variable "project_id" {
  type        = string
  sensitive   = true
  description = "The ID of the project"
}

variable "region" {
  type        = string
  description = "The region to deploy to"
}

variable "ssh_source_cidr" {
  type        = string
  description = "The source CIDR for SSH access"
}

variable "instance_name" {
  type        = string
  description = "The name of the instance"
}

variable "instance_type" {
  type        = string
  description = "The type of the instance"
}

variable "network_name" {
  type        = string
  description = "The name of the network"
}

variable "subnet_name" {
  type        = string
  description = "The name of the subnet"
}

resource "google_compute_network" "vpc" {
  name                    = var.network_name
  auto_create_subnetworks = false
  project                 = var.project_id
  tags                    = ["vpc-network"]
}

resource "google_compute_subnetwork" "subnet" {
  name          = var.subnet_name
  ip_cidr_range = "10.0.0.0/16"
  network       = google_compute_network.vpc.id
  project       = var.project_id
  region        = var.region
  tags          = ["vpc-subnet"]
}

resource "google_compute_firewall" "ssh" {
  name    = "ssh-firewall"
  network = google_compute_network.vpc.id
  project = var.project_id

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = [var.ssh_source_cidr]
  target_tags   = ["ssh-access"]
}

resource "google_compute_instance" "instance" {
  name         = var.instance_name
  machine_type = var.instance_type
  zone         = "${var.region}-a"
  project      = var.project_id

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.subnet.id
    network_ip = "10.0.0.2"
  }

  tags = ["ssh-access"]

  metadata = {
    ssh-keys = "username:${var.ssh_key}"
  }

  labels = {
    environment = "dev"
  }
}

variable "ssh_key" {
  type        = string
  sensitive   = true
  description = "The SSH public key"
}