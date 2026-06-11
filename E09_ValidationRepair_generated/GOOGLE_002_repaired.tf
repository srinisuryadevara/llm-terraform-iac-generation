provider "google" {
  project = var.project_id
  region  = var.region
}

variable "project_id" {
  type = string
}

variable "region" {
  type = string
}

variable "dataset_id" {
  type = string
}

variable "table_id" {
  type = string
}

variable "access_group_email" {
  type = string
}

resource "google_bigquery_dataset" "example" {
  dataset_id = var.dataset_id
  location   = var.region
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
  labels = {
    environment = "dev"
    project     = var.project_id
  }
}

resource "google_bigquery_dataset_iam_member" "example" {
  dataset_id = google_bigquery_dataset.example.dataset_id
  role       = "roles/bigquery.dataViewer"
  member     = "group:${var.access_group_email}"
}

resource "google_bigquery_dataset_iam_member" "example_editor" {
  dataset_id = google_bigquery_dataset.example.dataset_id
  role       = "roles/bigquery.dataEditor"
  member     = "group:${var.access_group_email}"
}

output "bigquery_dataset_id" {
  value = google_bigquery_dataset.example.dataset_id
}

output "bigquery_table_id" {
  value = google_bigquery_table.example.table_id
}

output "bigquery_dataset_iam_member_viewer" {
  value = google_bigquery_dataset_iam_member.example.member
}

output "bigquery_dataset_iam_member_editor" {
  value = google_bigquery_dataset_iam_member.example_editor.member
}