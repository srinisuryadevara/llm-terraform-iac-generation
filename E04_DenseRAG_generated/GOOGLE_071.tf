terraform {
  required_version = ">= 0.12"
}

variable "project_id" {}
variable "region" {
  default = "us-central1"
}
variable "database_version" {
  default = "POSTGRES_14"
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
variable "backup_retention_period" {
  default = 7
}
variable "private_network" {}

provider "google" {
  version = "~> 4.0"
  region  = var.region
  project = var.project_id
}

resource "google_compute_network" "private_network" {
  provider                = google
  project                 = var.project_id
  name                    = var.private_network
  auto_create_subnetworks = false
}

resource "google_compute_global_address" "private_ip_address" {
  provider      = google
  project       = var.project_id
  name          = "private-ip-address"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  ip_version    = "IPV4"
  prefix_length = 16
}

resource "google_service_networking_connection" "private_vpc_connection" {
  provider                = google
  project                 = var.project_id
  network                 = google_compute_network.private_network.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_address.name]
}

resource "google_sql_database_instance" "private_ip_instance" {
  provider            = google
  project             = var.project_id
  region              = var.region
  database_version   = var.database_version
  tier               = var.database_tier
  availability_type  = var.availability_type

  settings {
    tier                        = var.database_tier
    availability_type           = var.availability_type
    disk_autoresize             = true
    disk_size                   = 50
    disk_type                   = "PD_SSD"
    activation_policy           = "ALWAYS"
    deletion_protection         = false
    backup_configuration {
      enabled                        = true
      start_time                     = var.backup_start_time
      location                      = var.region
      retention_unit                = "COUNT"
      retention_period              = var.backup_retention_period
      transaction_log_retention_days = 7
    }
    ip_configuration {
      ipv4_enabled = false
      private_network = google_compute_network.private_network.id
    }
  }
}