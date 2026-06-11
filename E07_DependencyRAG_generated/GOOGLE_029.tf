variable "billing_account" {}
variable "org_id" {}
variable "region" {
  default = "us-central1"
}
variable "project_id" {}
variable "network_name" {}
variable "database_version" {}
variable "database_tier" {}
variable "backup_start_time" {}
variable "backup_retention_period" {}

provider "google" {
  version = "~>4.0"
  region      = var.region
  project     = var.project_id
}

resource "google_compute_network" "network" {
  name                    = var.network_name
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "subnetwork" {
  name          = "${var.network_name}-subnetwork"
  ip_cidr_range = "10.0.0.0/16"
  network       = google_compute_network.network.id
  region        = var.region
}

resource "google_sql_database_instance" "instance" {
  name                = "private-ip-instance"
  database_version   = var.database_version
  region              = var.region
  deletion_protection = false

  settings {
    tier              = var.database_tier
    availability_type = "REGIONAL"
    disk_size         = 50
    disk_type         = "PD_SSD"

    ip_configuration {
      ipv4_enabled   = false
      private_network = google_compute_network.network.id
    }

    backup_configuration {
      enabled                        = true
      start_time                     = var.backup_start_time
      location                       = var.region
      retention_unit                 = "COUNT"
      retention_used_period          = var.backup_retention_period
      transaction_log_retention_days = 7
    }
  }
}

resource "google_sql_database" "database" {
  name     = "example-database"
  instance = google_sql_database_instance.instance.name
}