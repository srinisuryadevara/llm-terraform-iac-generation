provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_bigquery_dataset" "example" {
  dataset_id                  = var.dataset_id
  friendly_name               = var.dataset_friendly_name
  description                 = var.dataset_description
  location                    = var.region
  default_table_expiration_ms = var.default_table_expiration_ms
}

resource "google_bigquery_table" "example" {
  dataset_id = google_bigquery_dataset.example.dataset_id
  table_id   = var.table_id

  schema = <<EOF
[
  {
    "name": "id",
    "type": "INTEGER",
    "mode": "NULLABLE"
  },
  {
    "name": "name",
    "type": "STRING",
    "mode": "NULLABLE"
  }
]
EOF
}

resource "google_bigquery_dataset_iam_member" "example" {
  dataset_id = google_bigquery_dataset.example.dataset_id
  role       = var.dataset_iam_role
  member     = var.dataset_iam_member
}

resource "google_bigquery_table_iam_member" "example" {
  table_id = google_bigquery_table.example.id
  role     = var.table_iam_role
  member   = var.table_iam_member
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

variable "dataset_friendly_name" {
  type = string
}

variable "dataset_description" {
  type = string
}

variable "default_table_expiration_ms" {
  type = number
}

variable "table_id" {
  type = string
}

variable "dataset_iam_role" {
  type = string
}

variable "dataset_iam_member" {
  type = string
}

variable "table_iam_role" {
  type = string
}

variable "table_iam_member" {
  type = string
}