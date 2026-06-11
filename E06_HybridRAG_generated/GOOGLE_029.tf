terraform {
  required_version = ">= 0.12"
}

###########################
# VARIABLES
############################

# Google Cloud variables
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

# Cloud SQL instance info
variable "instance_name" {}
variable "database_name" {}
variable "database_username" {}
variable "database_password" {}

############################
# PROVIDERS
############################

provider "google" {
  version = "~> 4.0"
  region  = var.region
  project = var.project_id
}

############################
# RESOURCES
############################

resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = "default"
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_range.name]
}

resource "google_compute_global_address" "private_ip_range" {
  name          = "cloud-sql-private-ip-range"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = "default"
}

resource "google_sql_database_instance" "postgress_instance" {
  name                = var.instance_name
  region              = var.region
  database_version   = var.database_version
  tier               = var.database_tier
  availability_type  = var.availability_type
  deletion_protection = false

  depends_on = [google_service_networking_connection.private_vpc_connection]

  settings {
    tier                        = var.database_tier
    availability_type           = var.availability_type
    disk_autoresize             = true
    disk_size                   = 50
    disk_type                   = "PD_SSD"
    ip_configuration {
      ipv4_enabled    = false
      private_network = "default"
    }
    maintenance_window {
      day  = 7
      hour = 0
    }
    database_flags {
      name  = "cloudsql.enable_pgaudit"
      value = "on"
    }
  }

  backup_configuration {
    binary_log_enabled = true
    enabled            = true
    start_time         = var.backup_start_time
  }
}

resource "google_sql_database" "database" {
  name     = var.database_name
  instance = google_sql_database_instance.postgress_instance.name
}

resource "google_sql_user" "users" {
  name     = var.database_username
  instance = google_sql_database_instance.postgress_instance.name
  host     = "%"
  password = var.database_password
}