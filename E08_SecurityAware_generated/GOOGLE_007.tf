provider "google" {
  project = var.project_id
  region  = var.region
}

variable "project_id" {
  type        = string
  description = "The ID of the project"
}

variable "region" {
  type        = string
  description = "The region to deploy to"
}

variable "ssh_source_cidr" {
  type        = string
  description = "The CIDR to allow SSH from"
}

variable "instance_name" {
  type        = string
  description = "The name of the instance"
}

variable "instance_type" {
  type        = string
  description = "The type of the instance"
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
  network = google_compute_network.vpc.name
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  source_ranges = [var.ssh_source_cidr]
  target_tags   = ["example-instance"]
  depends_on    = [google_compute_network.vpc]
  tags          = ["example-ssh-firewall"]
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
    ssh-keys = "example-user:${file("~/.ssh/id_rsa.pub")}"
  }

  depends_on = [google_compute_firewall.ssh]
  labels = {
    environment = "example-environment"
  }
}

resource "google_kms_key_ring" "example" {
  name     = "example-keyring"
  location = var.region
  project  = var.project_id
  labels = {
    environment = "example-environment"
  }
}

resource "google_kms_crypto_key" "example" {
  name            = "example-key"
  key_ring        = google_kms_key_ring.example.id
  rotation_period = "7776000s"
  labels = {
    environment = "example-environment"
  }
}

resource "google_compute_disk" "example" {
  name  = "example-disk"
  size  = 50
  type  = "pd-ssd"
  zone  = "${var.region}-a"
  labels = {
    environment = "example-environment"
  }
  disk_encryption_key {
    kms_key_self_link = google_kms_crypto_key.example.id
  }
}

resource "google_compute_attached_disk" "example" {
  disk     = google_compute_disk.example.id
  instance = google_compute_instance.example.id
}