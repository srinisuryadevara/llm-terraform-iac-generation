provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_bigquery_dataset" "example" {
  dataset_id                  = var.dataset_id
  location                    = var.location
  default_table_expiration_ms = var.table_expiration

  labels = {
    env        = var.env
    managed_by = "Terraform"
  }

  encryption_spec {
    kms_key_name = var.kms_key_name
  }
}

resource "google_bigquery_table" "example" {
  dataset_id = google_bigquery_dataset.example.dataset_id
  table_id   = var.table_id

  labels = {
    env        = var.env
    managed_by = "Terraform"
  }

  schema = var.table_schema

  encryption_spec {
    kms_key_name = var.kms_key_name
  }
}

resource "google_bigquery_dataset_iam_policy" "example" {
  dataset_id = google_bigquery_dataset.example.dataset_id
  policy     = data.google_iam_policy.example.policy
}

data "google_iam_policy" "example" {
  binding {
    role = "roles/bigquery.dataViewer"
    members = [
      "serviceAccount:${var.service_account_email}",
    ]
  }

  binding {
    role = "roles/bigquery.dataEditor"
    members = [
      "user:${var.data_editor_email}",
    ]
  }

  binding {
    role = "roles/bigquery.dataOwner"
    members = [
      "user:${var.data_owner_email}",
    ]
  }
}

variable "project_id" {
  type        = string
  description = "GCP project ID"
}

variable "region" {
  type        = string
  description = "GCP region"
}

variable "dataset_id" {
  type        = string
  description = "BigQuery dataset ID"
}

variable "location" {
  type        = string
  description = "BigQuery dataset location"
}

variable "table_id" {
  type        = string
  description = "BigQuery table ID"
}

variable "table_expiration" {
  type        = number
  description = "BigQuery table expiration in milliseconds"
}

variable "table_schema" {
  type        = string
  description = "BigQuery table schema"
}

variable "kms_key_name" {
  type        = string
  description = "KMS key name for encryption"
}

variable "env" {
  type        = string
  description = "Environment"
}

variable "service_account_email" {
  type        = string
  description = "Service account email"
}

variable "data_editor_email" {
  type        = string
  description = "Data editor email"
}

variable "data_owner_email" {
  type        = string
  description = "Data owner email"
}