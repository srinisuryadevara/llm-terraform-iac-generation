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
  description = "Dataflow role"
}

resource "google_iam_role_policy" "dataflow_policy" {
  role = google_iam_role.dataflow_role.id
  policy_data = jsonencode({
    "version" : "1",
    "bindings" : [
      {
        "role" : "roles/dataflow.worker",
        "members" : [
          "serviceAccount:${google_service_account.dataflow_service_account.email}"
        ]
      }
    ]
  })
}

resource "google_dataflow_flex_template_run" "dataflow_job" {
  provider                = google
  name                    = var.dataflow_job_name
  template_gcs_path       = var.template_gcs_path
  parameters              = var.parameters
  service_account_email   = google_service_account.dataflow_service_account.email
  staging_location        = "gs://${google_storage_bucket.staging_bucket.name}/staging"
  temp_location           = "gs://${google_storage_bucket.staging_bucket.name}/temp"
  additional_experiments = var.additional_experiments
  depends_on             = [google_iam_role_policy.dataflow_policy]
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

variable "dataflow_job_name" {
  type = string
}

variable "template_gcs_path" {
  type = string
}

variable "parameters" {
  type = map(string)
}

variable "additional_experiments" {
  type = list(string)
}