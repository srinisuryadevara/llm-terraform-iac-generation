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
variable "availability_type" {
  default = "REGIONAL"
}
variable "backup_start_time" {
  default = "00:00"
}
variable "backup_retention_period" {
  default = "7"
}
variable "private_network_name" {}

###########################
# PROVIDERS
###########################

provider "google" {
  version = "~> 4.0"
  region  = var.region
  project = var.project_id
}

###########################
# RESOURCES
###########################

resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = var.private_network_name
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_range.name]
}

resource "google_compute_global_address" "private_ip_range" {
  name          = "private-ip-range"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = var.private_network_name
}

resource "google_sql_database_instance" "postgre_sql_instance" {
  name                = "postgre-sql-instance"
  region              = var.region
  database_version   = var.database_version
  deletion_protection = false

  settings {
    tier              = var.database_tier
    availability_type = var.availability_type
    disk_size         = 50
    disk_type         = "PD_SSD"

    ip_configuration {
      ipv4_enabled = false
      private_network = var.private_network_name
    }

    backup_configuration {
      binary_log_enabled = true
      start_time          = var.backup_start_time
      location            = var.region
      retention_unit      = "COUNT"
      retention_period    = var.backup_retention_period
    }
  }
}