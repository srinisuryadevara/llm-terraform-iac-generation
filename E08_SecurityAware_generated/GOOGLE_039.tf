provider "google" {
  project = var.project_id
  region  = var.region
}

variable "project_id" {
  type        = string
  sensitive   = true
  description = "The ID of the project"
}

variable "region" {
  type        = string
  description = "The region to create resources in"
}

variable "instance_id" {
  type        = string
  description = "The ID of the Spanner instance"
}

variable "database_id" {
  type        = string
  description = "The ID of the Spanner database"
}

variable "iam_members" {
  type        = list(string)
  description = "The list of IAM members to grant roles to"
}

resource "google_spanner_instance" "example" {
  name          = var.instance_id
  config        = "regional-${var.region}"
  display_name  = "Example Spanner Instance"
  num_nodes     = 1
  labels        = {
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
  labels = {
    environment = "example"
  }
}

resource "google_kms_crypto_key" "example" {
  name     = "example-crypto-key"
  key_ring = google_kms_key_ring.example.id
  labels = {
    environment = "example"
  }
}

resource "google_spanner_instance_iam_member" "example" {
  for_each = toset(var.iam_members)
  instance = google_spanner_instance.example.name
  role     = "roles/spanner.databaseUser"
  member   = each.value
}

resource "google_kms_key_ring_iam_member" "example" {
  for_each = toset(var.iam_members)
  key_ring = google_kms_key_ring.example.id
  role     = "roles/owner"
  member   = each.value
}