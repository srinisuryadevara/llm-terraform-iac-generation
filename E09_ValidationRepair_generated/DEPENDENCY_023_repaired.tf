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
  labels = {
    environment = "dev"
    owner       = "terraform"
  }
}

resource "google_compute_subnetwork" "subnet" {
  name          = var.subnetwork_name
  ip_cidr_range = "10.0.1.0/24"
  network       = google_compute_network.vpc.id
  region        = var.region
  labels = {
    environment = "dev"
    owner       = "terraform"
  }
}

resource "google_compute_instance" "vm" {
  name         = var.instance_name
  machine_type = var.machine_type
  zone         = var.zone
  labels = {
    environment = "dev"
    owner       = "terraform"
  }

  boot_disk {
    initialize_params {
      image = var.image
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.subnet.id
  }
}

output "instance_id" {
  value       = google_compute_instance.vm.id
  description = "The ID of the instance"
}

output "instance_name" {
  value       = google_compute_instance.vm.name
  description = "The name of the instance"
}

output "instance_zone" {
  value       = google_compute_instance.vm.zone
  description = "The zone of the instance"
}

output "network_id" {
  value       = google_compute_network.vpc.id
  description = "The ID of the network"
}

output "network_name" {
  value       = google_compute_network.vpc.name
  description = "The name of the network"
}

output "subnetwork_id" {
  value       = google_compute_subnetwork.subnet.id
  description = "The ID of the subnetwork"
}

output "subnetwork_name" {
  value       = google_compute_subnetwork.subnet.name
  description = "The name of the subnetwork"
}