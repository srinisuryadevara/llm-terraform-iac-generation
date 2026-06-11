provider "google" {
  version = "~> 4.0"
  project = var.project_id
  region  = var.region
}

variable "project_id" {
  type        = string
  description = "The ID of the project to create the resources in"
}

variable "region" {
  type        = string
  description = "The region to create the resources in"
}

variable "dataflow_job_name" {
  type        = string
  description = "The name of the Dataflow job"
}

variable "staging_bucket_name" {
  type        = string
  description = "The name of the staging bucket"
}

variable "service_account_email" {
  type        = string
  description = "The email of the service account to use for the Dataflow job"
}

resource "google_storage_bucket" "staging_bucket" {
  name     = var.staging_bucket_name
  location = var.region
  force_destroy = true
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

resource "google_iam_role_binding" "dataflow_binding" {
  role = google_iam_role.dataflow_role.id
  members = [
    "serviceAccount:${google_service_account.dataflow_service_account.email}",
  ]
}

resource "google_dataflow_flex_template_run" "dataflow_job" {
  provider           = google
  project             = var.project_id
  region              = var.region
  template_gcs_path  = "gs://${google_storage_bucket.staging_bucket.name}/template"
  parameters = {
    "input" = "gs://${google_storage_bucket.staging_bucket.name}/input"
  }
  service_account_email = google_service_account.dataflow_service_account.email
}