provider "google" {
  project = var.project_id
  region  = var.region
}

variable "project_id" {
  type = string
}

variable "region" {
  type = string
}

variable "instance_name" {
  type = string
}

variable "machine_type" {
  type = string
}

variable "image" {
  type = string
}

variable "network_name" {
  type = string
}

variable "firewall_tag" {
  type = string
}

resource "google_compute_network" "vpc" {
  name                    = var.network_name
  auto_create_subnetworks = false
  labels = {
    environment = "dev"
    project     = var.project_id
  }
}

resource "google_compute_subnetwork" "subnet" {
  name          = "${var.network_name}-subnet"
  ip_cidr_range = "10.0.0.0/16"
  network       = google_compute_network.vpc.id
  labels = {
    environment = "dev"
    project     = var.project_id
  }
}

resource "google_compute_firewall" "allow_http" {
  name    = "${var.firewall_tag}-allow-http"
  network = google_compute_network.vpc.id
  labels = {
    environment = "dev"
    project     = var.project_id
  }

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  target_tags = [var.firewall_tag]
}

resource "google_compute_instance" "vm" {
  name         = var.instance_name
  machine_type = var.machine_type
  zone         = "${var.region}-a"
  labels = {
    environment = "dev"
    project     = var.project_id
  }

  boot_disk {
    initialize_params {
      image = var.image
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.subnet.id
  }

  tags = [var.firewall_tag]
}

output "instance_id" {
  value       = google_compute_instance.vm.id
  description = "The ID of the Compute Engine instance"
}

output "instance_name" {
  value       = google_compute_instance.vm.name
  description = "The name of the Compute Engine instance"
}

output "instance_zone" {
  value       = google_compute_instance.vm.zone
  description = "The zone of the Compute Engine instance"
}

output "network_id" {
  value       = google_compute_network.vpc.id
  description = "The ID of the Compute Engine network"
}

output "subnet_id" {
  value       = google_compute_subnetwork.subnet.id
  description = "The ID of the Compute Engine subnetwork"
}

output "firewall_id" {
  value       = google_compute_firewall.allow_http.id
  description = "The ID of the Compute Engine firewall"
}