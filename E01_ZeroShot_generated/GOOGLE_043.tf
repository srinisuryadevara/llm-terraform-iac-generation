provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_storage_bucket" "staging_bucket" {
  name     = var.staging_bucket_name
  location = var.region
  storage_class = "REGIONAL"
}

resource "google_service_account" "dataflow_service_account" {
  account_id = var.service_account_id
}

resource "google_service_account_key" "dataflow_service_account_key" {
  service_account_id = google_service_account.dataflow_service_account.id
}

resource "google_dataflow_job" "example_job" {
  name                = var.job_name
  template_gcs_path   = "gs://${google_storage_bucket.staging_bucket.name}/template"
  temp_gcs_location    = "gs://${google_storage_bucket.staging_bucket.name}/temp"
  service_account_email = google_service_account.dataflow_service_account.email
  parameters = {
    "input" = "gs://${google_storage_bucket.staging_bucket.name}/input"
    "output" = "gs://${google_storage_bucket.staging_bucket.name}/output"
  }
  depends_on = [google_dataflow-flex-template-job]
}

variable "project_id" {
  type = string
}

variable "region" {
  type = string
}

variable "staging_bucket_name" {
  type = string
}

variable "service_account_id" {
  type = string
}

variable "job_name" {
  type = string
}