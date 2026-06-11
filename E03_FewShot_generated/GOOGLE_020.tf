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

variable "access_group_email" {
  type        = string
  sensitive   = true
}

resource "google_bigquery_dataset" "example" {
  dataset_id = var.dataset_id
  location   = var.region
}

resource "google_bigquery_table" "example" {
  dataset_id = google_bigquery_dataset.example.dataset_id
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

resource "google_bigquery_dataset_iam_member" "example" {
  dataset_id = google_bigquery_dataset.example.dataset_id
  role       = "roles/bigquery.dataViewer"
  member     = "group:${var.access_group_email}"
}

resource "google_bigquery_table_iam_member" "example" {
  table_id = google_bigquery_table.example.id
  role     = "roles/bigquery.dataEditor"
  member   = "group:${var.access_group_email}"
}