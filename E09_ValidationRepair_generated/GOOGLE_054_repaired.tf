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
  sensitive   = true
}

variable "dataset_id" {
  type        = string
  sensitive   = true
}

variable "table_id" {
  type        = string
  sensitive   = true
}

variable "bigquery_service_account" {
  type        = string
  sensitive   = true
}

resource "google_bigquery_dataset" "example" {
  dataset_id                  = var.dataset_id
  friendly_name               = "example-dataset"
  description                 = "This is a test description"
  location                    = var.region
  labels = {
    environment = "dev"
    project     = var.project_id
  }
}

resource "google_bigquery_table" "example" {
  dataset_id = google_bigquery_dataset.example.dataset_id
  table_id   = var.table_id

  schema = jsonencode([
    {
      name = "name"
      type = "STRING"
      mode = "NULLABLE"
    },
    {
      name = "age"
      type = "INTEGER"
      mode = "NULLABLE"
    },
  ])

  labels = {
    environment = "dev"
    project     = var.project_id
  }

  depends_on = [
    google_bigquery_dataset.example
  ]
}

resource "google_bigquery_dataset_iam_member" "example" {
  dataset_id = google_bigquery_dataset.example.dataset_id
  role       = "roles/bigquery.dataViewer"
  member     = "serviceAccount:${var.bigquery_service_account}"
}

resource "google_bigquery_dataset_iam_member" "example_editor" {
  dataset_id = google_bigquery_dataset.example.dataset_id
  role       = "roles/bigquery.dataEditor"
  member     = "serviceAccount:${var.bigquery_service_account}"
}

resource "google_bigquery_dataset_iam_member" "example_owner" {
  dataset_id = google_bigquery_dataset.example.dataset_id
  role       = "roles/bigquery.dataOwner"
  member     = "serviceAccount:${var.bigquery_service_account}"
}

output "bigquery_dataset_id" {
  value       = google_bigquery_dataset.example.dataset_id
  description = "The ID of the BigQuery dataset"
}

output "bigquery_table_id" {
  value       = google_bigquery_table.example.table_id
  description = "The ID of the BigQuery table"
}

output "bigquery_dataset_iam_member_viewer" {
  value       = google_bigquery_dataset_iam_member.example.member
  description = "The member of the BigQuery dataset IAM member with viewer role"
}

output "bigquery_dataset_iam_member_editor" {
  value       = google_bigquery_dataset_iam_member.example_editor.member
  description = "The member of the BigQuery dataset IAM member with editor role"
}

output "bigquery_dataset_iam_member_owner" {
  value       = google_bigquery_dataset_iam_member.example_owner.member
  description = "The member of the BigQuery dataset IAM member with owner role"
}