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

variable "zone" {
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

resource "google_compute_network" "vpc" {
  name                    = "example-vpc"
  auto_create_subnetworks = false
  labels = {
    environment = "example"
    project     = var.project_id
  }
}

resource "google_compute_subnetwork" "subnet" {
  name          = "example-subnet"
  ip_cidr_range = "10.0.0.0/16"
  network       = google_compute_network.vpc.id
  region        = var.region
  labels = {
    environment = "example"
    project     = var.project_id
  }
}

resource "google_compute_firewall" "allow_http" {
  name    = "example-firewall"
  network = google_compute_network.vpc.id

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  target_tags = ["http-server"]
  labels = {
    environment = "example"
    project     = var.project_id
  }
}

resource "google_compute_instance" "example" {
  name         = var.instance_name
  machine_type = var.machine_type
  zone         = var.zone
  labels = {
    environment = "example"
    project     = var.project_id
  }

  boot_disk {
    initialize_params {
      image = var.image
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.subnet.id
    access_config {
    }
  }

  tags = ["http-server"]
}

output "instance_id" {
  value = google_compute_instance.example.id
}

output "instance_name" {
  value = google_compute_instance.example.name
}

output "instance_zone" {
  value = google_compute_instance.example.zone
}

output "instance_public_ip" {
  value = google_compute_instance.example.network_interface[0].access_config[0].nat_ip
}

output "vpc_id" {
  value = google_compute_network.vpc.id
}

output "subnet_id" {
  value = google_compute_subnetwork.subnet.id
}

output "firewall_id" {
  value = google_compute_firewall.allow_http.id
}