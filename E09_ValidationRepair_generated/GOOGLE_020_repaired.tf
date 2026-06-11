provider "google" {
  project = var.project_id
  region  = var.region
}

variable "project_id" {
  type        = string
  sensitive   = true
}

variable "region" {
  type        = string
  default     = "us-central1"
}

variable "dataset_id" {
  type        = string
}

variable "table_id" {
  type        = string
}

variable "description" {
  type        = string
}

variable "location" {
  type        = string
}

resource "google_bigquery_dataset" "dataset" {
  dataset_id                  = var.dataset_id
  friendly_name               = var.dataset_id
  description                 = var.description
  location                    = var.location
  default_table_expiration_ms = 3600000
  labels = {
    environment = "dev"
    project     = var.project_id
  }
}

resource "google_bigquery_table" "table" {
  dataset_id = google_bigquery_dataset.dataset.dataset_id
  table_id   = var.table_id
  labels = {
    environment = "dev"
    project     = var.project_id
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
}

resource "google_bigquery_dataset_iam_policy" "policy" {
  dataset_id = google_bigquery_dataset.dataset.dataset_id
  policy     = data.google_iam_policy.policy.policy
}

data "google_iam_policy" "policy" {
  binding {
    role = "roles/bigquery.dataViewer"
    members = [
      "user:admin@example.com",
    ]
  }

  binding {
    role = "roles/bigquery.dataEditor"
    members = [
      "serviceAccount:service-account@example.com",
    ]
  }
}

output "bigquery_dataset_id" {
  value       = google_bigquery_dataset.dataset.dataset_id
  description = "The ID of the BigQuery dataset"
}

output "bigquery_table_id" {
  value       = google_bigquery_table.table.table_id
  description = "The ID of the BigQuery table"
}

output "bigquery_dataset_iam_policy" {
  value       = google_bigquery_dataset_iam_policy.policy.policy
  description = "The IAM policy of the BigQuery dataset"
  sensitive   = true
}