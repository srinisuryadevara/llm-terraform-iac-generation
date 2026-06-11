variable "gcp_project" {
  type = string
}

variable "gcp_region" {
  type = string
}

variable "gcp_instance_type" {
  type = string
}

variable "gcp_disk_image" {
  type = string
}

variable "gcp_vm_address" {
  type = string
}

variable "gcp_network_name" {
  type = string
}

variable "gcp_subnetwork_name" {
  type = string
}

variable "gcp_subnetwork_cidr" {
  type = string
}

provider "google" {
  project = var.gcp_project
  region  = var.gcp_region
}

resource "google_compute_network" "gcp-network" {
  name                    = var.gcp_network_name
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "gcp-subnet1" {
  name          = var.gcp_subnetwork_name
  ip_cidr_range = var.gcp_subnetwork_cidr
  network       = google_compute_network.gcp-network.id
  region        = var.gcp_region
}

resource "google_compute_address" "gcp-ip" {
  name = "gcp-vm-ip-${var.gcp_region}"
  region = var.gcp_region
}

data "google_compute_zones" "available" {
  region = var.gcp_region
}

resource "google_compute_instance" "gcp-vm" {
  name         = "gcp-vm-${var.gcp_region}"
  machine_type = var.gcp_instance_type
  zone         = data.google_compute_zones.available.names[0]

  boot_disk {
    initialize_params {
      image = var.gcp_disk_image
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.gcp-subnet1.name
    address    = var.gcp_vm_address

    access_config {
      nat_ip = google_compute_address.gcp-ip.address
    }
  }
}