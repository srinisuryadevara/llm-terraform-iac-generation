#########################################################################################
# This configuration creates a Compute Engine instance in GCP
# with a network interface and firewall tag.
#########################################################################################

###########################
# VARIABLES
############################

# Google Cloud variables
variable "project_id" {}
variable "region" {
  default = "us-central1"
}
variable "zone" {
  default = "us-central1-a"
}

# Compute Engine instance variables
variable "instance_name" {}
variable "machine_type" {
  default = "f1-micro"
}
variable "image" {
  default = "debian-cloud/debian-9"
}

# Network variables
variable "network_name" {}
variable "subnet_name" {}
variable "subnet_ip" {
  default = "10.10.10.0/24"
}

# Firewall variables
variable "firewall_name" {}
variable "firewall_tag" {}

############################
# PROVIDERS
############################

provider "google" {
  version = "~> 4.0"
  project = var.project_id
  region  = var.region
}

############################
# RESOURCES
############################

# Create the network
resource "google_compute_network" "network" {
  name                    = var.network_name
  auto_create_subnetworks = false
}

# Create the subnet
resource "google_compute_subnetwork" "subnet" {
  name          = var.subnet_name
  ip_cidr_range = var.subnet_ip
  network       = google_compute_network.network.id
  region        = var.region
}

# Create the firewall rule
resource "google_compute_firewall" "firewall" {
  name    = var.firewall_name
  network = google_compute_network.network.id

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  target_tags = [var.firewall_tag]
}

# Create the Compute Engine instance
resource "google_compute_instance" "instance" {
  name         = var.instance_name
  machine_type = var.machine_type
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = var.image
    }
  }

  network_interface {
    network = google_compute_network.network.id
    subnetwork = google_compute_subnetwork.subnet.id
    access_config {
    }
  }

  tags = [var.firewall_tag]
}