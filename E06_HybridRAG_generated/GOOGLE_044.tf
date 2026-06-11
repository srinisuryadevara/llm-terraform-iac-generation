terraform {
  required_version = ">= 0.12"
}

variable "project_id" {}
variable "region" {
  default = "us-central1"
}
variable "database_version" {
  default = "POSTGRES_13"
}
variable "database_tier" {
  default = "db-g1-small"
}
variable "availability_type" {
  default = "REGIONAL"
}
variable "backup_start_time" {
  default = "00:00"
}
variable "backup_retention_period" {
  default = "7"
}

provider "google" {
  version = "~> 4.0"
  project = var.project_id
  region  = var.region
}

resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = google_compute_network.private_network.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_range.name]
}

resource "google_compute_global_address" "private_ip_range" {
  name          = "private-ip-range"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.private_network.id
}

resource "google_compute_network" "private_network" {
  name                    = "private-network"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "private_subnetwork" {
  name          = "private-subnetwork"
  ip_cidr_range = "10.0.0.0/16"
  network       = google_compute_network.private_network.id
  region        = var.region
}

resource "google_sql_database_instance" "private_ip_instance" {
  name                = "private-ip-instance"
  region              = var.region
  database_version   = var.database_version
  tier               = var.database_tier
  availability_type  = var.availability_type

  depends_on = [google_service_networking_connection.private_vpc_connection]

  settings {
    tier                        = var.database_tier
    availability_type           = var.availability_type
    disk_autoresize             = true
    disk_size                   = 50
    disk_type                   = "PD_SSD"
    activation_policy           = "ALWAYS"
    backup_configuration {
      binary_log_enabled = true
      enabled            = true
      start_time         = var.backup_start_time
      location           = var.region
    }
    ip_configuration {
      ipv4_enabled = false
      private_network = google_compute_network.private_network.id
    }
    maintenance_window {
      day  = 7
      hour = 0
    }
  }
}