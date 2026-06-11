variable "project" {
  type        = string
  description = "GCP project ID"
}

variable "region" {
  type        = string
  description = "GCP region"
}

variable "database_instance_name" {
  type        = string
  description = "Cloud SQL database instance name"
}

variable "database_version" {
  type        = string
  description = "Cloud SQL database version"
}

variable "database_tier" {
  type        = string
  description = "Cloud SQL database tier"
}

variable "database_availability_type" {
  type        = string
  description = "Cloud SQL database availability type"
}

variable "database_disk_size" {
  type        = number
  description = "Cloud SQL database disk size"
}

variable "database_disk_type" {
  type        = string
  description = "Cloud SQL database disk type"
}

variable "database_user_name" {
  type        = string
  description = "Cloud SQL database user name"
}

variable "database_user_password" {
  type        = string
  sensitive   = true
  description = "Cloud SQL database user password"
}

variable "database_labels" {
  type        = map(string)
  description = "Cloud SQL database labels"
}

resource "google_sql_database_instance" "example" {
  name                = var.database_instance_name
  region              = var.region
  database_version    = var.database_version
  tier                = var.database_tier
  availability_type   = var.database_availability_type
  disk_size           = var.database_disk_size
  disk_type           = var.database_disk_type
  deletion_protection = false

  depends_on = [google_service_networking_connection.example]

  labels = var.database_labels
}

resource "google_service_networking_connection" "example" {
  network                 = google_compute_network.example.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.example.name]
}

resource "google_compute_global_address" "example" {
  name          = "example-address"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.example.id
}

resource "google_compute_network" "example" {
  name                    = "example-network"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "example" {
  name          = "example-subnetwork"
  ip_cidr_range = "10.0.0.0/16"
  network       = google_compute_network.example.id
}

resource "google_sql_database" "example" {
  name     = "example-database"
  instance = google_sql_database_instance.example.name
}

resource "google_sql_user" "example" {
  name     = var.database_user_name
  instance = google_sql_database_instance.example.name
  host     = "%"
  password = var.database_user_password
}

resource "google_compute_firewall" "example" {
  name    = "example-firewall"
  network = google_compute_network.example.name

  allow {
    protocol = "tcp"
    ports    = ["3306"]
  }

  source_ranges = ["10.0.0.0/16"]
}

resource "google_kms_key_ring" "example" {
  name     = "example-keyring"
  location = var.region
}

resource "google_kms_crypto_key" "example" {
  name     = "example-key"
  key_ring = google_kms_key_ring.example.id
}

resource "google_kms_crypto_key_version" "example" {
  crypto_key = google_kms_crypto_key.example.id
}

resource "google_sql_database_instance" "encrypted" {
  name                = "${var.database_instance_name}-encrypted"
  region              = var.region
  database_version    = var.database_version
  tier                = var.database_tier
  availability_type   = var.database_availability_type
  disk_size           = var.database_disk_size
  disk_type           = var.database_disk_type
  disk_encryption_key = google_kms_crypto_key_version.example.id
  deletion_protection = false

  depends_on = [google_service_networking_connection.example]

  labels = var.database_labels
}