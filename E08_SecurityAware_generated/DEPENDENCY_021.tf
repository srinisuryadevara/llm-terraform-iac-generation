provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_compute_network" "vpc" {
  name                    = var.network_name
  auto_create_subnetworks = false
  mtu                     = 1460
  tags                    = var.tags
}

resource "google_compute_subnetwork" "subnet" {
  name          = var.subnet_name
  ip_cidr_range = var.subnet_cidr
  network       = google_compute_network.vpc.id
  region        = var.region
  tags          = var.tags
}

resource "google_compute_firewall" "ssh" {
  name    = var.firewall_name
  network = google_compute_network.vpc.name
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  source_ranges = [var.ssh_source_cidr]
  target_tags   = ["ssh-access"]
  tags          = var.tags
}

resource "google_compute_instance" "vm" {
  name         = var.instance_name
  machine_type = var.machine_type
  zone         = var.zone
  tags         = concat(["ssh-access"], var.tags)

  boot_disk {
    initialize_params {
      image = var.image
      size  = var.disk_size
      type  = var.disk_type
      labels = var.tags
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.subnet.id
  }

  metadata = {
    ssh-keys = "${var.ssh_username}:${var.ssh_public_key}"
  }

  labels = var.tags
}

variable "project_id" {
  type        = string
  sensitive   = true
  description = "GCP project ID"
}

variable "region" {
  type        = string
  description = "GCP region"
}

variable "network_name" {
  type        = string
  description = "VPC network name"
}

variable "subnet_name" {
  type        = string
  description = "Subnet name"
}

variable "subnet_cidr" {
  type        = string
  description = "Subnet CIDR"
}

variable "firewall_name" {
  type        = string
  description = "Firewall rule name"
}

variable "ssh_source_cidr" {
  type        = string
  description = "SSH source CIDR"
}

variable "instance_name" {
  type        = string
  description = "Compute instance name"
}

variable "machine_type" {
  type        = string
  description = "Machine type"
}

variable "zone" {
  type        = string
  description = "GCP zone"
}

variable "image" {
  type        = string
  description = "Boot disk image"
}

variable "disk_size" {
  type        = number
  description = "Boot disk size"
}

variable "disk_type" {
  type        = string
  description = "Boot disk type"
}

variable "ssh_username" {
  type        = string
  sensitive   = true
  description = "SSH username"
}

variable "ssh_public_key" {
  type        = string
  sensitive   = true
  description = "SSH public key"
}

variable "tags" {
  type        = list(string)
  description = "Resource tags"
}