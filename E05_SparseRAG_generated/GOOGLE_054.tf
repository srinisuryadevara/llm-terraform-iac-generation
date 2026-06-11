terraform {
  backend "gcs" {
    prefix  = "terraform/state"
    bucket  = var.gcp_bucket
  }
}

provider "google" {
  project     = var.gcp_project
  region      = var.gcp_region
}

provider "google-beta" {
  project     = var.gcp_project
  region      = var.gcp_region
}

locals {
  project = var.gcp_project
  config = {
    project = local.project
    dataset = var.bigquery_dataset
    table   = var.bigquery_table
    location = var.gcp_region
  }
}

variable "gcp_project" {
  type = string
}

variable "gcp_region" {
  type = string
}

variable "gcp_bucket" {
  type = string
}

variable "bigquery_dataset" {
  type = string
}

variable "bigquery_table" {
  type = string
}

resource "google_bigquery_dataset" "dataset" {
  dataset_id = local.config.dataset
  project    = local.config.project
  location   = local.config.location
}

resource "google_bigquery_table" "table" {
  dataset_id = google_bigquery_dataset.dataset.dataset_id
  table_id   = local.config.table
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