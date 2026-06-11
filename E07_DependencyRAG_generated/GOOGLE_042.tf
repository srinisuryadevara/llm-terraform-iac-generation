variable "project_id" {
  type = string
}

variable "region" {
  type = string
}

variable "database_version" {
  type = string
}

variable "availability_type" {
  type = string
}

variable "tier" {
  type = string
}

variable "backup_start_time" {
  type = string
}

variable "backup_retention_days" {
  type = number
}

variable "database_name" {
  type = string
}

variable "username" {
  type = string
}

variable "password" {
  type      = string
  sensitive = true
}

variable "private_network_name" {
  type = string
}

provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_compute_network" "private_network" {
  name                    = var.private_network_name
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "private_subnetwork" {
  name          = "${var.private_network_name}-subnetwork"
  ip_cidr_range = "10.0.0.0/16"
  network       = google_compute_network.private_network.id
  region        = var.region
}

resource "google_sql_database_instance" "private_instance" {
  name                = "private-instance"
  database_version   = var.database_version
  region              = var.region
  availability_type   = var.availability_type
  deletion_protection = false

  settings {
    tier              = var.tier
    disk_size         = 50
    disk_type         = "PD_SSD"
    activation_policy = "ALWAYS"

    ip_configuration {
      ipv4_enabled = false
      private_network = google_compute_network.private_network.id
    }

    backup_configuration {
      enabled                        = true
      start_time                     = var.backup_start_time
      location                       = var.region
      backup_retention_days          = var.backup_retention_days
      transaction_log_retention_days = 7
    }
  }
}

resource "google_sql_database" "database" {
  name     = var.database_name
  instance = google_sql_database_instance.private_instance.name
}

resource "google_sql_user" "users" {
  name     = var.username
  instance = google_sql_database_instance.private_instance.name
  host     = "%"
  password = var.password
}