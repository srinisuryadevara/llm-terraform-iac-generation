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

variable "database_password" {
  type      = string
  sensitive = true
}

variable "database_username" {
  type = string
}

variable "instance_name" {
  type = string
}

resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = google_compute_network.private_network.id
  service                  = "servicenetworking.googleapis.com"
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
  region        = var.region
  network       = google_compute_network.private_network.id
}

resource "google_sql_database_instance" "private_ip_instance" {
  name                = var.instance_name
  region               = var.region
  database_version     = "POSTGRES_14"
  deletion_protection = false

  settings {
    tier                        = "db-g1-small"
    disk_size                  = 50
    availability_type          = "REGIONAL"
    database_flags {
      name  = "cloudsql.iam_authentication"
      value = "on"
    }
    ip_configuration {
      ipv4_enabled    = false
      private_network = google_compute_network.private_network.id
    }
    backup_configuration {
      enabled                        = true
      start_time                     = "00:00"
      location                       = var.region
      point_in_time_recovery_enabled = true
    }
    maintenance_window {
      day  = 7
      hour = 0
    }
  }
}

resource "google_sql_user" "users" {
  name     = var.database_username
  instance = google_sql_database_instance.private_ip_instance.name
  host     = "%"
  password = var.database_password
}