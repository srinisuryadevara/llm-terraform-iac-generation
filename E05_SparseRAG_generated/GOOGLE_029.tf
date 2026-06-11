###########################
# VARIABLES
############################

variable "project_id" {}
variable "region" {
  default = "us-central1"
}
variable "database_version" {
  default = "POSTGRES_14"
}
variable "database_tier" {
  default = "db-g1-small"
}
variable "availability_zone" {
  default = "us-central1-a"
}
variable "backup_start_time" {
  default = "00:00"
}
variable "backup_retention_period" {
  default = "7"
}

############################
# PROVIDERS
############################

provider "google" {
  version = "~> 4.0"
  region  = var.region
}

############################
# RESOURCES
############################

resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = "default"
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = ["${google_compute_global_address.private_ip.address}/28"]
}

resource "google_compute_global_address" "private_ip" {
  name          = "cloud-sql-private-ip"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 28
  network       = "default"
}

resource "google_sql_database_instance" "postgre_sql" {
  name                = "postgre-sql-instance"
  region              = var.region
  database_version   = var.database_version
  deletion_protection = false

  settings {
    tier              = var.database_tier
    availability_type = "REGIONAL"
    disk_size         = 50
    disk_type         = "PD_SSD"

    ip_configuration {
      ipv4_enabled    = false
      private_network = "default"
    }

    backup_configuration {
      enabled                        = true
      start_time                     = var.backup_start_time
      location                       = var.region
      retention_unit                 = "COUNT"
      retention_used_period          = var.backup_retention_period
      binary_log_enabled             = true
      point_in_time_recovery_enabled = true
    }
  }
}