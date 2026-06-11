provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_storage_bucket" "staging_bucket" {
  name     = var.staging_bucket_name
  location = var.region
  storage_class = "REGIONAL"
  labels = {
    environment = "dataflow"
    application = "dataflow-job"
  }
}

resource "google_service_account" "dataflow_service_account" {
  account_id = var.service_account_id
  labels = {
    environment = "dataflow"
    application = "dataflow-job"
  }
}

resource "google_service_account_key" "dataflow_service_account_key" {
  service_account_id = google_service_account.dataflow_service_account.id
}

resource "google_iam_role" "dataflow_role" {
  name        = var.dataflow_role_name
  title       = var.dataflow_role_name
  description = "Dataflow role"
  labels = {
    environment = "dataflow"
    application = "dataflow-job"
  }
}

resource "google_iam_role_policy" "dataflow_policy" {
  role    = google_iam_role.dataflow_role.id
  policy  = jsonencode({
    "bindings": [
      {
        "role": "roles/dataflow.worker",
        "members": [
          "serviceAccount:${google_service_account.dataflow_service_account.email}",
        ]
      },
    ]
  })
}

resource "google_iam_member" "dataflow_member" {
  role    = google_iam_role.dataflow_role.id
  member  = "serviceAccount:${google_service_account.dataflow_service_account.email}"
}

resource "google_dataflow_flex_template_run" "dataflow_job" {
  provider                = google
  project                 = var.project_id
  region                  = var.region
  template_gcs_path       = var.template_gcs_path
  parameters              = var.parameters
  service_account_email   = google_service_account.dataflow_service_account.email
  staging_location        = "gs://${google_storage_bucket.staging_bucket.name}/staging"
  container_spec_gcs_path = var.container_spec_gcs_path
  labels = {
    environment = "dataflow"
    application = "dataflow-job"
  }
  depends_on              = [google_iam_member.dataflow_member]
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

variable "dataflow_worker_image" {
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

output "staging_bucket_name" {
  value = google_storage_bucket.staging_bucket.name
}

output "staging_bucket_id" {
  value = google_storage_bucket.staging_bucket.id
}

output "service_account_email" {
  value = google_service_account.dataflow_service_account.email
}

output "service_account_id" {
  value = google_service_account.dataflow_service_account.id
}

output "dataflow_role_name" {
  value = google_iam_role.dataflow_role.name
}

output "dataflow_job_id" {
  value = google_dataflow_flex_template_run.dataflow_job.id
}