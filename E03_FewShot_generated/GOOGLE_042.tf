variable "project_id" {
  type        = string
  description = "The ID of the project to create the resources in"
}

variable "region" {
  type        = string
  description = "The region to create the resources in"
}

variable "database_version" {
  type        = string
  description = "The version of the database to create"
}

variable "database_tier" {
  type        = string
  description = "The tier of the database to create"
}

variable "availability_type" {
  type        = string
  description = "The availability type of the database to create"
}

variable "backup_start_time" {
  type        = string
  description = "The start time for the daily backup configuration in UTC"
}

variable "backup_retention_period" {
  type        = number
  description = "The number of days to retain backups"
}

variable "private_network_id" {
  type        = string
  description = "The ID of the private network to create the database in"
}

provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = var.private_network_id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_range.name]
}

resource "google_compute_global_address" "private_ip_range" {
  name          = "private-ip-range"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = var.private_network_id
}

resource "google_sql_database_instance" "private_ip_instance" {
  name                = "private-ip-instance"
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
      private_network = var.private_network_id
    }

    backup_configuration {
      enabled                        = true
      start_time                     = var.backup_start_time
      location                       = var.region
      point_in_time_recovery_enabled = true
      transaction_log_retention_days = var.backup_retention_period
    }
  }
}