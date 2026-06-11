provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_service_account" "cloudsql" {
  account_id = "cloudsql-sa"
  description = "Service account for Cloud SQL"
}

resource "google_project_iam_member" "cloudsql" {
  project = var.project_id
  role    = "roles/cloudsql.client"
  member  = "serviceAccount:${google_service_account.cloudsql.email}"
}

resource "google_compute_network" "private_network" {
  name                    = "private-network"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "private_subnetwork" {
  name          = "private-subnetwork"
  ip_cidr_range = "10.0.0.0/16"
  network       = google_compute_network.private_network.id
}

resource "google_compute_global_address" "private_ip_address" {
  name          = "private-ip-address"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.private_network.id
}

resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = google_compute_network.private_network.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_address.name]
}

resource "google_sql_database_instance" "private_postgresql_instance" {
  name                = "private-postgresql-instance"
  region              = var.region
  database_version   = "POSTGRES_14"
  deletion_protection = false

  settings {
    tier              = "db-g1-small"
    availability_type = "REGIONAL"
    disk_size         = 50
    disk_type         = "PD_SSD"
    disk_encryption   = "Google-managed encryption"

    ip_configuration {
      ipv4_enabled    = false
      private_network = google_compute_network.private_network.id
    }

    backup_configuration {
      enabled                        = true
      start_time                     = "00:00"
      location                       = var.region
      encryption_key_name            = google_kms_keyring.keyring.id
      point_in_time_recovery_enabled = true
    }

    maintenance_window {
      day  = 7
      hour = 0
    }
  }

  depends_on = [google_service_networking_connection.private_vpc_connection]
}

resource "google_kms_keyring" "keyring" {
  name     = "cloudsql-keyring"
  location = var.region
}

resource "google_kms_key" "key" {
  name            = "cloudsql-key"
  key_ring        = google_kms_keyring.keyring.id
  rotation_period = "604800s"
}

resource "google_kms_crypto_key_version" "version" {
  crypto_key = google_kms_key.key.id
}

resource "google_kms_crypto_key_iam_member" "member" {
  crypto_key_id = google_kms_key.key.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:${google_service_account.cloudsql.email}"
}

variable "project_id" {
  type        = string
  description = "The ID of the project"
}

variable "region" {
  type        = string
  description = "The region of the project"
}