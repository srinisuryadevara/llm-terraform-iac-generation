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

provider "google" {
  project = var.gcp_project
  region  = var.gcp_region
}

resource "google_compute_network" "gcp-network" {
  name                    = "gcp-network"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "gcp-subnet1" {
  name          = "gcp-subnet1"
  ip_cidr_range = "10.0.1.0/24"
  network       = google_compute_network.gcp-network.id
  region        = var.gcp_region
}

resource "google_compute_address" "gcp-ip" {
  name = "gcp-vm-ip"
  region = var.gcp_region
}

data "google_compute_zones" "available" {
  region = var.gcp_region
}

resource "google_compute_instance" "gcp-vm" {
  name         = "gcp-vm"
  machine_type = var.gcp_instance_type
  zone         = data.google_compute_zones.available.names[0]

  boot_disk {
    initialize_params {
      image = var.gcp_disk_image
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.gcp-subnet1.id
    access_config {
      nat_ip = google_compute_address.gcp-ip.address
    }
  }

  metadata_startup_script = file("vm_userdata.sh")
}