provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_bigquery_dataset" "example" {
  dataset_id                  = var.dataset_id
  friendly_name               = var.dataset_name
  location                    = var.location
  delete_contents_on_destroy = true
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
  member     = "user:${var.user_email}"
}

resource "google_bigquery_dataset_iam_member" "example_editor" {
  dataset_id = google_bigquery_dataset.example.dataset_id
  role       = "roles/bigquery.dataEditor"
  member     = "serviceAccount:${var.service_account_email}"
}

variable "project_id" {
  type        = string
  sensitive   = true
}

variable "region" {
  type        = string
  default     = "US"
}

variable "dataset_id" {
  type        = string
}

variable "dataset_name" {
  type        = string
}

variable "location" {
  type        = string
}

variable "table_id" {
  type        = string
}

variable "user_email" {
  type        = string
  sensitive   = true
}

variable "service_account_email" {
  type        = string
  sensitive   = true
}