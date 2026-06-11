provider "google" {
  project = var.project_id
  region  = var.region
}

variable "project_id" {
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
  description = "Name of the Compute Engine instance"
}

variable "instance_type" {
  type        = string
  description = "Type of the Compute Engine instance"
}

resource "google_compute_network" "vpc" {
  name                    = "example-vpc"
  auto_create_subnetworks = false
  tags                    = ["example-vpc"]
}

resource "google_compute_subnetwork" "subnet" {
  name          = "example-subnet"
  ip_cidr_range = "10.0.0.0/16"
  network       = google_compute_network.vpc.id
  region        = var.region
  tags          = ["example-subnet"]
}

resource "google_compute_firewall" "ssh" {
  name    = "example-ssh-firewall"
  network = google_compute_network.vpc.id
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  source_ranges = [var.ssh_source_cidr]
  target_tags   = ["example-instance"]
}

resource "google_compute_instance" "example" {
  name         = var.instance_name
  machine_type = var.instance_type
  zone         = "${var.region}-a"
  tags         = ["example-instance", "example-vpc"]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.subnet.id
  }

  metadata = {
    enable-oslogin = "TRUE"
  }

  metadata_startup_script = "echo 'Hello World!' > /test.txt"

  labels = {
    environment = "example-env"
  }
}

resource "google_compute_disk" "example" {
  name  = "example-disk"
  size  = 50
  type  = "pd-ssd"
  zone  = "${var.region}-a"
  labels = {
    environment = "example-env"
  }
  disk_encryption_key {
    kms_key_self_link = google_kms_crypto_key.example.self_link
  }
}

resource "google_kms_key_ring" "example" {
  name     = "example-keyring"
  location = var.region
  project  = var.project_id
}

resource "google_kms_crypto_key" "example" {
  name     = "example-key"
  key_ring = google_kms_key_ring.example.id
  purpose  = "ENCRYPTION"
}

resource "google_kms_crypto_key_version" "example" {
  crypto_key = google_kms_crypto_key.example.id
}