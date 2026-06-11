provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_bigquery_dataset" "example" {
  dataset_id                  = var.dataset_id
  friendly_name               = var.dataset_name
  description                 = var.dataset_description
  location                    = var.location
  default_table_expiration_ms = var.table_expiration

  labels = {
    env        = var.environment
    managed_by = "Terraform"
  }
}

resource "google_bigquery_table" "example" {
  dataset_id = google_bigquery_dataset.example.id
  table_id   = var.table_id

  time_partitioning {
    type = "DAY"
  }

  labels = {
    env        = var.environment
    managed_by = "Terraform"
  }
}

resource "google_bigquery_dataset_iam_member" "example" {
  dataset_id = google_bigquery_dataset.example.id
  role       = "roles/bigquery.dataViewer"
  member     = "serviceAccount:${var.service_account_email}"
}

resource "google_bigquery_table_iam_member" "example" {
  table_id = google_bigquery_table.example.id
  role     = "roles/bigquery.dataViewer"
  member   = "serviceAccount:${var.service_account_email}"
}

variable "project_id" {
  type        = string
  description = "GCP Project ID"
}

variable "region" {
  type        = string
  description = "GCP Region"
}

variable "dataset_id" {
  type        = string
  description = "BigQuery Dataset ID"
}

variable "dataset_name" {
  type        = string
  description = "BigQuery Dataset Name"
}

variable "dataset_description" {
  type        = string
  description = "BigQuery Dataset Description"
}

variable "location" {
  type        = string
  description = "BigQuery Dataset Location"
}

variable "table_id" {
  type        = string
  description = "BigQuery Table ID"
}

variable "table_expiration" {
  type        = number
  description = "BigQuery Table Expiration in milliseconds"
}

variable "environment" {
  type        = string
  description = "Environment (e.g. dev, prod)"
}

variable "service_account_email" {
  type        = string
  description = "Service Account Email"
}