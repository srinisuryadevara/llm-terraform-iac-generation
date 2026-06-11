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

# Set this using the environment variable TF_VAR_database_password
variable "database_password" {}

variable "private_network_name" {}
variable "private_network_self_link" {}

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
  network                 = var.private_network_name
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip.address]
}

resource "google_compute_global_address" "private_ip" {
  name          = "cloud-sql-private-ip"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  ip_version    = "IPV4"
  prefix_length = 16
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
      private_network = var.private_network_self_link
    }

    backup_configuration {
      binary_log_enabled = true
      start_time          = var.backup_start_time
      location            = var.region
    }
  }
}

resource "google_sql_user" "users" {
  name     = "postgres"
  instance = google_sql_database_instance.postgre_instance.name
  host     = "%"
  password = var.database_password
}