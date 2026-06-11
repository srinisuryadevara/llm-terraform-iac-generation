terraform {
  backend "gcs" {
    prefix  = "terraform/state"
    bucket  = var.gcp_bucket_name
  }
}

provider "google" {
  project     = var.gcp_project_id
  region      = var.gcp_region
}

provider "google-beta" {
  project     = var.gcp_project_id
  region      = var.gcp_region
}

locals {
  project = var.gcp_project_id
  config = {
    project = local.project
    region = var.gcp_region
    dataset_id = var.bigquery_dataset_id
    table_id = var.bigquery_table_id
  }
}

variable "gcp_project_id" {
  type        = string
  sensitive   = true
}

variable "gcp_region" {
  type        = string
  default     = "us-central1"
}

variable "gcp_bucket_name" {
  type        = string
  sensitive   = true
}

variable "bigquery_dataset_id" {
  type        = string
}

variable "bigquery_table_id" {
  type        = string
}

variable "bigquery_dataset_location" {
  type        = string
  default     = "US"
}

variable "bigquery_table_schema" {
  type        = string
}

resource "google_bigquery_dataset" "dataset" {
  dataset_id                  = var.bigquery_dataset_id
  location                    = var.bigquery_dataset_location
  delete_contents_on_destroy = true
}

resource "google_bigquery_table" "table" {
  dataset_id = google_bigquery_dataset.dataset.dataset_id
  table_id   = var.bigquery_table_id
  schema     = var.bigquery_table_schema
}

resource "google_bigquery_dataset_iam_member" "owner" {
  dataset_id = google_bigquery_dataset.dataset.dataset_id
  role       = "roles/bigquery.dataOwner"
  member     = "user:${var.gcp_project_id}"
}

resource "google_bigquery_dataset_iam_member" "reader" {
  dataset_id = google_bigquery_dataset.dataset.dataset_id
  role       = "roles/bigquery.dataReader"
  member     = "allUsers"
}

resource "google_bigquery_table_iam_member" "owner" {
  table_id = google_bigquery_table.table.id
  role     = "roles/bigquery.dataOwner"
  member   = "user:${var.gcp_project_id}"
}

resource "google_bigquery_table_iam_member" "reader" {
  table_id = google_bigquery_table.table.id
  role     = "roles/bigquery.dataReader"
  member   = "allUsers"
}