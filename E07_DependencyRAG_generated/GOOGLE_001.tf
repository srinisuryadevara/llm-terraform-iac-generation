provider "google" {
  version = "~> 4.0"
  project = var.project_id
  region  = var.region
}

variable "project_id" {
  type = string
}

variable "region" {
  type = string
}

variable "bucket_name" {
  type = string
}

variable "service_account_name" {
  type = string
}

variable "dataflow_job_name" {
  type = string
}

variable "dataflow_job_file" {
  type = string
}

resource "google_storage_bucket" "staging_bucket" {
  name     = var.bucket_name
  location = var.region
  force_destroy = true
}

resource "google_service_account" "dataflow_service_account" {
  account_id = var.service_account_name
}

resource "google_service_account_key" "dataflow_service_account_key" {
  service_account_id = google_service_account.dataflow_service_account.id
}

resource "google_project_iam_member" "dataflow_service_account_iam_member" {
  project = var.project_id
  role    = "roles/dataflow.worker"
  member  = "serviceAccount:${google_service_account.dataflow_service_account.email}"
}

resource "google_dataflow_job" "dataflow_job" {
  name                = var.dataflow_job_name
  template_gcs_path   = "gs://${google_storage_bucket.staging_bucket.name}/${var.dataflow_job_file}"
  temp_gcs_location   = "gs://${google_storage_bucket.staging_bucket.name}/temp"
  service_account_email = google_service_account.dataflow_service_account.email
  depends_on = [
    google_project_iam_member.dataflow_service_account_iam_member
  ]
}

resource "google_storage_bucket_object" "dataflow_job_file" {
  name   = var.dataflow_job_file
  bucket = google_storage_bucket.staging_bucket.name
  source = file("${path.module}/${var.dataflow_job_file}")
}