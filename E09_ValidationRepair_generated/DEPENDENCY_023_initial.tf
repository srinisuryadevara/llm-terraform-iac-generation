provider "google" {
  project = var.project_id
  region  = var.region
}

variable "project_id" {
  type        = string
  sensitive   = true
}

variable "region" {
  type        = string
  sensitive   = true
}

variable "zone" {
  type        = string
  sensitive   = true
}

variable "network_name" {
  type        = string
  sensitive   = true
}

variable "subnetwork_name" {
  type        = string
  sensitive   = true
}

variable "instance_name" {
  type        = string
  sensitive   = true
}

variable "machine_type" {
  type        = string
  sensitive   = true
}

variable "image" {
  type        = string
  sensitive   = true
}

resource "google_compute_network" "vpc" {
  name                    = var.network_name
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "subnet" {
  name          = var.subnetwork_name
  ip_cidr_range = "10.0.1.0/24"
  network       = google_compute_network.vpc.id
  region        = var.region
}

resource "google_compute_instance" "vm" {
  name         = var.instance_name
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