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
  dataset_config = {
    project = local.project
    dataset_id = var.bigquery_dataset_id
    location = var.gcp_region
    table_id = var.bigquery_table_id
  }
}

variable "gcp_project_id" {
  type = string
}

variable "gcp_region" {
  type = string
}

variable "gcp_bucket_name" {
  type = string
}

variable "bigquery_dataset_id" {
  type = string
}

variable "bigquery_table_id" {
  type = string
}

resource "google_bigquery_dataset" "dataset" {
  dataset_id = local.dataset_config.dataset_id
  location   = local.dataset_config.location
}

resource "google_bigquery_table" "table" {
  dataset_id = google_bigquery_dataset.dataset.dataset_id
  table_id   = local.dataset_config.table_id
}

resource "google_bigquery_dataset_iam_member" "owner" {
  dataset_id = google_bigquery_dataset.dataset.dataset_id
  role       = "roles/bigquery.dataOwner"
  member     = "user:${var.gcp_owner_email}"
}

resource "google_bigquery_dataset_iam_member" "reader" {
  dataset_id = google_bigquery_dataset.dataset.dataset_id
  role       = "roles/bigquery.dataViewer"
  member     = "user:${var.gcp_reader_email}"
}

variable "gcp_owner_email" {
  type = string
}

variable "gcp_reader_email" {
  type = string
}