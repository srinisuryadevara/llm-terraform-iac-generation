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
  default = "db-n1-standard-1"
}
variable "availability_type" {
  default = "REGIONAL"
}
variable "disk_size" {
  default = 50
}
variable "disk_type" {
  default = "PD_SSD"
}
variable "backup_start_time" {
  default = "00:00"
}
variable "backup_retention_days" {
  default = 7
}
variable "private_network" {}

provider "google" {
  version = "~> 4.0"
  region  = var.region
  project = var.project_id
}

resource "google_compute_global_address" "private_ip_address" {
  provider = google
  name          = "private-ip-address"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  ip_version    = "IPV4"
  prefix_length = 16
}

resource "google_service_networking_connection" "private_vpc_connection" {
  provider = google
  network                 = var.private_network
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_address.name]
}

resource "google_sql_database_instance" "private_postgres_instance" {
  provider = google
  name                = "private-postgres-instance"
  region              = var.region
  database_version   = var.database_version
  deletion_protection = false

  settings {
    tier              = var.database_tier
    availability_type = var.availability_type
    disk_size         = var.disk_size
    disk_type         = var.disk_type

    ip_configuration {
      ipv4_enabled    = false
      private_network = var.private_network
    }

    backup_configuration {
      enabled                        = true
      start_time                     = var.backup_start_time
      location                       = var.region
      backup_retention_settings {
        retained_backups = var.backup_retention_days
      }
    }
  }

  depends_on = [google_service_networking_connection.private_vpc_connection]
}