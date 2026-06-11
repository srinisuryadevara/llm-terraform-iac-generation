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

variable "database_version" {
  type = string
}

variable "database_tier" {
  type = string
}

variable "database_name" {
  type = string
}

variable "database_username" {
  type = string
}

variable "database_password" {
  type      = string
  sensitive = true
}

variable "backup_start_time" {
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
  network       = google_compute_network.private_network.id
  region        = var.region
}

resource "google_sql_database_instance" "private_ip_database" {
  name                = "private-ip-database"
  region               = var.region
  database_version     = var.database_version
  deletion_protection  = false
  depends_on          = [google_service_networking_connection.private_vpc_connection]

  settings {
    tier              = var.database_tier
    availability_type = "REGIONAL"
    disk_size         = 50
    disk_type         = "PD_SSD"

    ip_configuration {
      ipv4_enabled    = false
      private_network = google_compute_network.private_network.id
    }

    backup_configuration {
      enabled                        = true
      start_time                     = var.backup_start_time
      location                      = var.region
      point_in_time_recovery_enabled = true
    }
  }
}

resource "google_sql_database" "database" {
  name     = var.database_name
  instance = google_sql_database_instance.private_ip_database.name
}

resource "google_sql_user" "database_user" {
  name     = var.database_username
  instance = google_sql_database_instance.private_ip_database.name
  host     = "%"
  password = var.database_password
}