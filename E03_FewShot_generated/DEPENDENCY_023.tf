variable "project_id" {
  type        = string
  sensitive   = true
}

variable "region" {
  type        = string
  sensitive   = false
}

variable "zone" {
  type        = string
  sensitive   = false
}

variable "machine_type" {
  type        = string
  sensitive   = false
}

variable "image" {
  type        = string
  sensitive   = false
}

variable "network_name" {
  type        = string
  sensitive   = false
}

variable "subnetwork_name" {
  type        = string
  sensitive   = false
}

provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_compute_network" "vpc" {
  name                    = var.network_name
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "subnet" {
  name          = var.subnetwork_name
  ip_cidr_range = "10.0.0.0/16"
  network       = google_compute_network.vpc.id
  region        = var.region
}

resource "google_compute_instance" "vm" {
  name         = "test-vm"
  machine_type = var.machine_type
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = var.image
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.subnet.id
  }
}