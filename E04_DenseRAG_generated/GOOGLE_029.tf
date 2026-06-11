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
variable "backup_start_time" {
  default = "00:00"
}
variable "private_network" {}
variable "private_ip_address" {}

provider "google" {
  version = "~> 4.0"
  region  = var.region
  project = var.project_id
}

resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = var.private_network
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_address.name]
}

resource "google_compute_global_address" "private_ip_address" {
  name          = var.private_ip_address
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  ip_version    = "IPV4"
  prefix_length = 16
}

resource "google_sql_database_instance" "private_ip_instance" {
  name                = "private-ip-instance"
  region              = var.region
  database_version   = var.database_version
  tier               = var.database_tier
  availability_type  = var.availability_type

  depends_on = [google_service_networking_connection.private_vpc_connection]

  settings {
    tier              = var.database_tier
    availability_type = var.availability_type

    ip_configuration {
      ipv4_enabled    = false
      private_network = var.private_network
    }

    backup_configuration {
      enabled                        = true
      start_time                     = var.backup_start_time
      location                       = var.region
      backup_retention_settings {
        retained_backups = 7
        retention_unit   = "COUNT"
      }
    }
  }
}