###########################
# VARIABLES
############################

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

############################
# PROVIDERS
############################

provider "google" {
  version = "~> 4.0"
  region  = var.region
}

provider "google-beta" {
  version = "~> 4.0"
  region  = var.region
}

############################
# RESOURCES
############################

resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = "default"
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = ["${google_compute_global_address.private_ip.address}/${google_compute_global_address.private_ip.prefix_length}"]
}

resource "google_compute_global_address" "private_ip" {
  name          = "cloud-sql-private-ip"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = "default"
}

resource "google_sql_database_instance" "postgre_instance" {
  name                = "postgre-instance"
  region              = var.region
  database_version   = var.database_version
  deletion_protection = false

  settings {
    tier              = var.database_tier
    availability_type = var.availability_type
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
      backup_retention_period        = var.backup_retention_period
      transaction_log_retention_days = 7
    }
  }
}