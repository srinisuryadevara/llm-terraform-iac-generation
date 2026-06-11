variable "project_id" {
  type        = string
  description = "The ID of the project where the BigQuery dataset will be created"
}

variable "dataset_id" {
  type        = string
  description = "The ID of the BigQuery dataset"
}

variable "table_id" {
  type        = string
  description = "The ID of the BigQuery table"
}

variable "location" {
  type        = string
  description = "The location where the BigQuery dataset will be created"
}

provider "google" {
  project = var.project_id
  region  = var.location
}

resource "google_bigquery_dataset" "dataset" {
  dataset_id = var.dataset_id
  location   = var.location
}

resource "google_bigquery_table" "table" {
  dataset_id = google_bigquery_dataset.dataset.dataset_id
  table_id   = var.table_id

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

resource "google_bigquery_dataset_iam_member" "reader" {
  dataset_id = google_bigquery_dataset.dataset.dataset_id
  role       = "roles/bigquery.reader"
  member     = "allAuthenticatedUsers"
}

resource "google_bigquery_dataset_iam_member" "writer" {
  dataset_id = google_bigquery_dataset.dataset.dataset_id
  role       = "roles/bigquery.writer"
  member     = "serviceAccount:${google_service_account.writer.email}"
}

resource "google_service_account" "writer" {
  account_id = "bigquery-writer"
}

resource "google_bigquery_table_iam_member" "reader" {
  table_id = google_bigquery_table.table.id
  role     = "roles/bigquery.reader"
  member   = "allAuthenticatedUsers"
}

resource "google_bigquery_table_iam_member" "writer" {
  table_id = google_bigquery_table.table.id
  role     = "roles/bigquery.writer"
  member   = "serviceAccount:${google_service_account.writer.email}"
}