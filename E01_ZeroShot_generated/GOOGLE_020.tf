provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_bigquery_dataset" "dataset" {
  dataset_id = var.dataset_id
  project    = var.project_id
  location   = var.location

  labels = {
    env = var.env
  }
}

resource "google_bigquery_table" "table" {
  dataset_id = google_bigquery_dataset.dataset.dataset_id
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

resource "google_bigquery_dataset_iam_member" "owner" {
  dataset_id = google_bigquery_dataset.dataset.dataset_id
  role       = "roles/bigquery.dataOwner"
  member     = var.owner_member
}

resource "google_bigquery_dataset_iam_member" "reader" {
  dataset_id = google_bigquery_dataset.dataset.dataset_id
  role       = "roles/bigquery.dataReader"
  member     = var.reader_member
}

resource "google_bigquery_dataset_iam_member" "writer" {
  dataset_id = google_bigquery_dataset.dataset.dataset_id
  role       = "roles/bigquery.dataWriter"
  member     = var.writer_member
}

variable "project_id" {
  type = string
}

variable "region" {
  type = string
}

variable "location" {
  type = string
}

variable "dataset_id" {
  type = string
}

variable "table_id" {
  type = string
}

variable "env" {
  type = string
}

variable "owner_member" {
  type = string
}

variable "reader_member" {
  type = string
}

variable "writer_member" {
  type = string
}