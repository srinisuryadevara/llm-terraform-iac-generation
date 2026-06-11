# Configure the Google Cloud Provider
provider "google" {
  project = var.project_id
  region  = var.region
}

# Create a storage bucket for staging
resource "google_storage_bucket" "staging_bucket" {
  name     = var.staging_bucket_name
  location = var.region
  storage_class = "REGIONAL"
  labels = {
    environment = "dataflow"
    purpose     = "staging"
  }
}

# Create a service account for Dataflow
resource "google_service_account" "dataflow_service_account" {
  account_id = var.service_account_id
  labels = {
    environment = "dataflow"
    purpose     = "service-account"
  }
}

# Create a service account key for Dataflow
resource "google_service_account_key" "dataflow_service_account_key" {
  service_account_id = google_service_account.dataflow_service_account.id
  labels = {
    environment = "dataflow"
    purpose     = "key"
  }
}

# Create a custom IAM role for Dataflow
resource "google_iam_role" "dataflow_role" {
  name        = var.dataflow_role_name
  description = "Dataflow role"
  labels = {
    environment = "dataflow"
    purpose     = "role"
  }
}

# Create a custom IAM role policy for Dataflow
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
  labels = {
    environment = "dataflow"
    purpose     = "policy"
  }
}

# Create a Dataflow flex template run
resource "google_dataflow_flex_template_run" "dataflow_job" {
  provider                = google
  name                    = var.dataflow_job_name
  template_gcs_path       = var.template_gcs_path
  parameters              = var.parameters
  service_account_email   = google_service_account.dataflow_service_account.email
  staging_location        = "gs://${google_storage_bucket.staging_bucket.name}/staging"
  temp_location           = "gs://${google_storage_bucket.staging_bucket.name}/temp"
  additional_experiments = var.additional_experiments
  labels = {
    environment = "dataflow"
    purpose     = "job"
  }
  depends_on             = [google_iam_role_policy.dataflow_policy]
}

# Input variables
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

# Output key resource attributes
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

output "dataflow_job_name" {
  value = google_dataflow_flex_template_run.dataflow_job.name
}

output "dataflow_job_id" {
  value = google_dataflow_flex_template_run.dataflow_job.id
}