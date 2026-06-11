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

variable "dataset_id" {
  type        = string
  description = "The ID of the BigQuery dataset"
}

variable "table_id" {
  type        = string
  description = "The ID of the BigQuery table"
}

variable "iam_members" {
  type        = list(string)
  description = "The list of IAM members to grant access to the BigQuery dataset"
}

resource "google_bigquery_dataset" "example" {
  dataset_id = var.dataset_id
  project    = var.project_id
  location   = var.region

  labels = {
    env        = "prod"
    managed-by = "terraform"
  }

  access {
    role          = "roles/bigquery.dataViewer"
    special_group = "projectOwners"
  }

  access {
    role          = "roles/bigquery.dataEditor"
    user_by_email = var.iam_members
  }
}

resource "google_bigquery_table" "example" {
  dataset_id = google_bigquery_dataset.example.dataset_id
  table_id   = var.table_id

  labels = {
    env        = "prod"
    managed-by = "terraform"
  }

  schema = jsonencode([
    {
      name = "id"
      type = "INTEGER"
      mode = "NULLABLE"
    },
    {
      name = "name"
      type = "STRING"
      mode = "NULLABLE"
    }
  ])

  encryption_specification {
    kms_key_name = google_kms_crypto_key.example.id
  }
}

resource "google_kms_key_ring" "example" {
  name     = "bigquery-keyring"
  location = var.region
}

resource "google_kms_crypto_key" "example" {
  name            = "bigquery-key"
  key_ring        = google_kms_key_ring.example.id
  rotation_period = "100000s"
}

resource "google_kms_crypto_key_version" "example" {
  crypto_key = google_kms_crypto_key.example.id
}