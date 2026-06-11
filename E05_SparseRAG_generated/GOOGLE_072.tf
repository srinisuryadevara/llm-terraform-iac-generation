variable "project_id" {
  type        = string
  description = "The ID of the project to create the Dataflow job in"
}

variable "region" {
  type        = string
  default     = "us-central1"
  description = "The region to create the Dataflow job in"
}

variable "staging_bucket_name" {
  type        = string
  description = "The name of the staging bucket to create"
}

variable "service_account_email" {
  type        = string
  description = "The email address of the service account to create"
}

variable "service_account_display_name" {
  type        = string
  description = "The display name of the service account to create"
}

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
  account_id   = "dataflow-service-account"
  display_name = var.service_account_display_name
}

resource "google_project_iam_member" "dataflow_service_account_runner" {
  project = var.project_id
  role    = "roles/dataflow.worker"
  member  = "serviceAccount:${google_service_account.dataflow_service_account.email}"
}

resource "google_project_iam_member" "dataflow_service_account_viewer" {
  project = var.project_id
  role    = "roles/viewer"
  member  = "serviceAccount:${google_service_account.dataflow_service_account.email}"
}

resource "google_dataflow_job" "example_job" {
  name                = "example-dataflow-job"
  template_gcs_path   = "gs://${google_storage_bucket.staging_bucket.name}/example-template"
  temp_gcs_location   = "gs://${google_storage_bucket.staging_bucket.name}/temp"
  service_account_email = google_service_account.dataflow_service_account.email
  parameters = {
    input = "gs://${google_storage_bucket.staging_bucket.name}/input"
    output = "gs://${google_storage_bucket.staging_bucket.name}/output"
  }
}

output "staging_bucket_name" {
  value = google_storage_bucket.staging_bucket.name
}

output "service_account_email" {
  value = google_service_account.dataflow_service_account.email
}

output "dataflow_job_id" {
  value = google_dataflow_job.example_job.id
}