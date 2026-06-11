provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = var.vpc_network
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [var.private_ip_range]
}

resource "google_sql_database_instance" "postgres_instance" {
  name                = var.instance_name
  region              = var.region
  database_version   = "POSTGRES_14"
  deletion_protection = false

  settings {
    tier              = var.instance_tier
    availability_type = "REGIONAL"
    disk_size         = var.disk_size
    disk_type         = "PD_SSD"

    ip_configuration {
      ipv4_enabled = false
      private_network = var.vpc_network
    }

    backup_configuration {
      enabled                        = true
      start_time                     = var.backup_start_time
      location                      = var.backup_location
      point_in_time_recovery_enabled = true
    }
  }
}

variable "project_id" {
  type        = string
  sensitive   = true
}

variable "region" {
  type        = string
}

variable "vpc_network" {
  type        = string
}

variable "private_ip_range" {
  type        = string
}

variable "instance_name" {
  type        = string
}

variable "instance_tier" {
  type        = string
}

variable "disk_size" {
  type        = number
}

variable "backup_start_time" {
  type        = string
}

variable "backup_location" {
  type        = string
}