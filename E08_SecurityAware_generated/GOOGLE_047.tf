provider "google" {
  project = var.project_id
  region  = var.region
}

variable "project_id" {
  type        = string
  sensitive   = true
  description = "GCP Project ID"
}

variable "region" {
  type        = string
  description = "GCP Region"
}

variable "ssh_source_cidr" {
  type        = string
  description = "CIDR for SSH access"
}

variable "instance_name" {
  type        = string
  description = "Name of the Compute Engine instance"
}

variable "instance_type" {
  type        = string
  description = "Type of the Compute Engine instance"
}

variable "network_name" {
  type        = string
  description = "Name of the VPC network"
}

variable "subnet_name" {
  type        = string
  description = "Name of the subnet"
}

resource "google_compute_network" "vpc" {
  name                    = var.network_name
  auto_create_subnetworks = false
  mtu                     = 1460
  routing_mode            = "REGIONAL"
  tags                    = ["vpc-network"]
}

resource "google_compute_subnetwork" "subnet" {
  name          = var.subnet_name
  ip_cidr_range = "10.0.0.0/16"
  network       = google_compute_network.vpc.id
  region        = var.region
  tags          = ["vpc-subnet"]
}

resource "google_compute_firewall" "ssh" {
  name    = "allow-ssh"
  network = google_compute_network.vpc.id
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  source_ranges = [var.ssh_source_cidr]
  target_tags   = ["ssh-access"]
  description   = "Allow SSH access from specific CIDR"
  tags          = ["firewall-rule"]
}

resource "google_compute_instance" "vm" {
  name         = var.instance_name
  machine_type = var.instance_type
  zone         = "${var.region}-a"
  tags         = ["ssh-access"]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
      size  = 50
      type  = "PD_STANDARD"
      disk_encryption_key_raw = var.disk_encryption_key
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.subnet.id
  }

  metadata = {
    enable-oslogin = "TRUE"
  }

  shielded_instance_config {
    enable_secure_boot          = true
    enable_vtpm                 = true
    enable_integrity_monitoring = true
  }

  labels = {
    environment = "dev"
    owner       = "terraform"
  }
}

variable "disk_encryption_key" {
  type        = string
  sensitive   = true
  description = "Disk encryption key"
}