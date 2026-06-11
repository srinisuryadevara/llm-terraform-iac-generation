provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = google_compute_network.private_network.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_vpc_range.name]
}

resource "google_compute_global_address" "private_vpc_range" {
  name          = "private-vpc-range"
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

resource "google_sql_database_instance" "private_postgresql_instance" {
  name                = "private-postgresql-instance"
  region               = var.region
  database_version     = "POSTGRES_14"
  deletion_protection  = false
  depends_on           = [google_service_networking_connection.private_vpc_connection]

  settings {
    tier                        = "db-g1-small"
    availability_type          = "REGIONAL"
    disk_autoresize             = true
    disk_autoresize_limit       = 0
    disk_size                   = 50
    disk_type                   = "PD_SSD"
    maintenance_window {
      day  = 7
      hour = 0
    }
    maintenance_window_update_track = "stable"
    point_in_time_recovery_enabled  = true
    replication_type               = "ASYNCHRONOUS"
    activation_policy              = "ALWAYS"
    ip_configuration {
      ipv4_enabled = false
      private_network = google_compute_network.private_network.id
    }
    backup_configuration {
      enabled                        = true
      start_time                     = "00:00"
      location                      = var.region
      point_in_time_recovery_enabled = true
      transaction_log_retention_days = 7
      retained_backups               = 7
      backup_retention_settings {
        retained_backups = 7
        retention_unit  = "COUNT"
      }
    }
  }
}

variable "project_id" {
  type = string
}

variable "region" {
  type = string
}