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

resource "google_iam_role" "dataflow_role" {
  name        = var.dataflow_role_name
  title       = var.dataflow_role_name
  description = "Dataflow role"
}

resource "google_iam_role_binding" "dataflow_binding" {
  role = google_iam_role.dataflow_role.id
  members = [
    "serviceAccount:${google_service_account.dataflow_service_account.email}",
  ]
}

resource "google_iam_project_binding" "dataflow_project_binding" {
  project = var.project_id
  role    = google_iam_role.dataflow_role.id
  members = [
    "serviceAccount:${google_service_account.dataflow_service_account.email}",
  ]
}

resource "google_dataflow_job" "example_job" {
  name                = var.job_name
  template_gcs_path   = var.template_gcs_path
  temp_gcs_location   = "gs://${google_storage_bucket.staging_bucket.name}/temp"
  service_account_email = google_service_account.dataflow_service_account.email
  parameters = {
    "inputFile" = "gs://${google_storage_bucket.staging_bucket.name}/input.txt"
    "outputFile" = "gs://${google_storage_bucket.staging_bucket.name}/output.txt"
  }
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

variable "dataflow_role_name" {
  type = string
}

variable "job_name" {
  type = string
}

variable "template_gcs_path" {
  type = string
}