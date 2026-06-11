provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_bigquery_dataset" "example" {
  dataset_id = var.dataset_id
  project    = var.project_id
  location   = var.region
}

resource "google_bigquery_table" "example" {
  dataset_id = google_bigquery_dataset.example.dataset_id
  table_id   = var.table_id
  schema     = var.table_schema
}

resource "google_bigquery_dataset_iam_policy" "example" {
  dataset_id = google_bigquery_dataset.example.dataset_id
  policy     = var.dataset_iam_policy
}

resource "google_bigquery_table_iam_policy" "example" {
  table_id = google_bigquery_table.example.table_id
  policy   = var.table_iam_policy
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

variable "table_schema" {
  type = string
}

variable "dataset_iam_policy" {
  type = string
}

variable "table_iam_policy" {
  type = string
}