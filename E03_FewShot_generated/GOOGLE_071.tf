provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = var.vpc_network
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [var.peering_range]
}

resource "google_sql_database_instance" "private_ip_postgres" {
  name                = var.instance_name
  region              = var.region
  database_version   = "POSTGRES_14"
  deletion_protection = false

  settings {
    tier              = var.tier
    availability_type = "REGIONAL"
    disk_size         = var.disk_size
    disk_type         = var.disk_type

    ip_configuration {
      ipv4_enabled    = false
      private_network = var.vpc_network
    }

    backup_configuration {
      binary_log_enabled = true
      enabled            = true
      start_time         = var.backup_start_time
    }

    maintenance_window {
      day  = var.maintenance_day
      hour = var.maintenance_hour
    }
  }
}

variable "project_id" {
  type        = string
  sensitive   = true
}

variable "region" {
  type = string
}

variable "vpc_network" {
  type = string
}

variable "peering_range" {
  type = string
}

variable "instance_name" {
  type = string
}

variable "tier" {
  type = string
}

variable "disk_size" {
  type = number
}

variable "disk_type" {
  type = string
}

variable "backup_start_time" {
  type = string
}

variable "maintenance_day" {
  type = number
}

variable "maintenance_hour" {
  type = number
}