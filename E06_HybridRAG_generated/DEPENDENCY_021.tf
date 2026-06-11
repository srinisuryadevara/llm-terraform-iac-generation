provider "google" {
  credentials = file(var.credentials_file)
  project     = var.project_id
  region      = var.region
}

resource "google_compute_network" "main" {
  name                    = var.network_name
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "public" {
  name          = var.public_subnet_name
  ip_cidr_range = var.public_subnet_cidr
  region        = var.region
  network       = google_compute_network.main.id
}

resource "google_compute_address" "gcp-ip" {
  name = var.instance_ip_name
  region = var.region
}

resource "google_compute_instance" "gcp-vm" {
  name         = var.instance_name
  machine_type = var.instance_type
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = var.disk_image
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.public.name
    access_config {
      nat_ip = google_compute_address.gcp-ip.address
    }
  }

  metadata_startup_script = file(var.startup_script)
}

variable "credentials_file" {
  type        = string
  sensitive   = true
}

variable "project_id" {
  type = string
}

variable "region" {
  type = string
}

variable "network_name" {
  type = string
}

variable "public_subnet_name" {
  type = string
}

variable "public_subnet_cidr" {
  type = string
}

variable "instance_ip_name" {
  type = string
}

variable "instance_name" {
  type = string
}

variable "instance_type" {
  type = string
}

variable "zone" {
  type = string
}

variable "disk_image" {
  type = string
}

variable "startup_script" {
  type = string
}