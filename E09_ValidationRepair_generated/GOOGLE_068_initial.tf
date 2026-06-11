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

resource "google_iam_role" "dataflow_worker_role" {
  name        = var.dataflow_worker_role_name
  title       = var.dataflow_worker_role_name
  description = "Dataflow worker role"
}

resource "google_iam_role" "dataflow_runner_role" {
  name        = var.dataflow_runner_role_name
  title       = var.dataflow_runner_role_name
  description = "Dataflow runner role"
}

resource "google_iam_policy" "dataflow_policy" {
  binding {
    role = google_iam_role.dataflow_worker_role.id
    members = [
      "serviceAccount:${google_service_account.dataflow_service_account.email}",
    ]
  }
  binding {
    role = google_iam_role.dataflow_runner_role.id
    members = [
      "serviceAccount:${google_service_account.dataflow_service_account.email}",
    ]
  }
}

resource "google_iam_policy" "dataflow_storage_policy" {
  binding {
    role = "roles/storage.objectViewer"
    members = [
      "serviceAccount:${google_service_account.dataflow_service_account.email}",
    ]
  }
}

resource "google_dataflow_flex_template_run" "example" {
  provider                = google
  project                 = var.project_id
  region                  = var.region
  template_gcs_path       = var.template_gcs_path
  parameters              = var.parameters
  service_account_email   = google_service_account.dataflow_service_account.email
  staging_location        = "gs://${google_storage_bucket.staging_bucket.name}/staging"
  container_spec_gcs_path = var.container_spec_gcs_path
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

variable "dataflow_worker_role_name" {
  type = string
}

variable "dataflow_runner_role_name" {
  type = string
}

variable "template_gcs_path" {
  type = string
}

variable "parameters" {
  type = map(string)
}

variable "container_spec_gcs_path" {
  type = string
}