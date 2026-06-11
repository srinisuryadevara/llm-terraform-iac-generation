provider "google" {
  project = var.project_id
  region  = var.region
}

variable "project_id" {
  type        = string
  description = "GCP Project ID"
}

variable "region" {
  type        = string
  description = "GCP Region"
}

variable "instance_id" {
  type        = string
  description = "Spanner Instance ID"
}

variable "database_id" {
  type        = string
  description = "Spanner Database ID"
}

variable "iam_members" {
  type        = list(string)
  description = "List of IAM members to grant roles to"
}

resource "google_spanner_instance" "example" {
  name                = var.instance_id
  config              = "regional-${var.region}"
  display_name        = "Example Spanner Instance"
  num_nodes           = 1
  labels              = {
    environment = "example"
  }
}

resource "google_spanner_database" "example" {
  instance = google_spanner_instance.example.name
  name     = var.database_id
  encryption_config {
    kms_key_name = google_kms_key_ring.example.id
  }
  labels = {
    environment = "example"
  }
}

resource "google_kms_key_ring" "example" {
  name     = "example-key-ring"
  location = var.region
  project  = var.project_id
}

resource "google_kms_crypto_key" "example" {
  name     = "example-key"
  key_ring = google_kms_key_ring.example.id
  purpose  = "ENCRYPTION"
}

resource "google_spanner_database_iam_member" "example" {
  database = google_spanner_database.example.name
  role     = "roles/spanner.databaseReader"
  member   = var.iam_members
}

resource "google_spanner_instance_iam_member" "example" {
  instance = google_spanner_instance.example.name
  role     = "roles/spanner.instanceUser"
  member   = var.iam_members
}

resource "google_kms_key_ring_iam_member" "example" {
  key_ring = google_kms_key_ring.example.id
  role     = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member   = var.iam_members
}