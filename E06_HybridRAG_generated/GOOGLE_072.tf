terraform {
  backend "gcs" {
    prefix  = "terraform/state"
    bucket  = var.bucket_name
  }
}

variable "project_id" {
  type = string
}

variable "region" {
  type    = string
  default = "us-central1"
}

variable "bucket_name" {
  type = string
}

variable "service_account_email" {
  type = string
}

variable "dataflow_job_name" {
  type = string
}

variable "dataflow_job_file" {
  type = string
}

provider "google" {
  project = var.project_id
  region  = var.region
}

provider "google-beta" {
  project = var.project_id
  region  = var.region
}

resource "google_storage_bucket" "staging_bucket" {
  name     = var.bucket_name
  location = var.region
}

resource "google_service_account" "dataflow_service_account" {
  account_id = "dataflow-service-account"
}

resource "google_service_account_key" "dataflow_service_account_key" {
  service_account_id = google_service_account.dataflow_service_account.id
}

resource "google_iam_role" "dataflow_role" {
  name        = "dataflow-role"
  title       = "Dataflow Role"
  description = "Role for Dataflow job"
}

resource "google_iam_role_binding" "dataflow_role_binding" {
  role = google_iam_role.dataflow_role.name
  members = [
    "serviceAccount:${google_service_account.dataflow_service_account.email}",
  ]
}

resource "google_dataflow_job" "example_job" {
  name                = var.dataflow_job_name
  template_gcs_path   = "gs://${google_storage_bucket.staging_bucket.name}/${var.dataflow_job_file}"
  temp_gcs_location   = "gs://${google_storage_bucket.staging_bucket.name}/temp"
  service_account_email = google_service_account.dataflow_service_account.email
  machine_type        = "n1-standard-1"
  max_workers         = 5
}

output "staging_bucket_name" {
  value = google_storage_bucket.staging_bucket.name
}

output "dataflow_job_id" {
  value = google_dataflow_job.example_job.id
}

output "dataflow_service_account_email" {
  value = google_service_account.dataflow_service_account.email
}