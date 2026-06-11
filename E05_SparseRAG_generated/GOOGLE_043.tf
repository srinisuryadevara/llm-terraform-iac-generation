#########################################################################################
# This configuration creates a Dataflow job, staging bucket, and service account in GCP
#########################################################################################

###########################
# VARIABLES
############################

variable "project_id" {}
variable "region" {
  default = "us-central1"
}
variable "bucket_name" {}
variable "service_account_name" {}
variable "dataflow_job_name" {}
variable "dataflow_job_file" {}
variable "dataflow_job_class" {}
variable "dataflow_job_args" {
  type = list(string)
  default = []
}

############################
# PROVIDERS
############################

provider "google" {
  version = "~> 4.0"
  project = var.project_id
  region  = var.region
}

############################
# RESOURCES
############################

resource "google_storage_bucket" "staging_bucket" {
  name     = var.bucket_name
  location = var.region
  storage_class = "REGIONAL"
}

resource "google_service_account" "dataflow_service_account" {
  account_id   = var.service_account_name
  display_name = "Dataflow Service Account"
}

resource "google_project_iam_member" "dataflow_service_account_role" {
  project = var.project_id
  role    = "roles/dataflow.worker"
  member  = "serviceAccount:${google_service_account.dataflow_service_account.email}"
}

resource "google_dataflow_flex_template_run" "dataflow_job" {
  provider                = google
  project                 = var.project_id
  region                  = var.region
  template_gcs_path       = "${google_storage_bucket.staging_bucket.name}/${var.dataflow_job_file}"
  parameters = {
    "job-name" = var.dataflow_job_name
  }
  service_account_email = google_service_account.dataflow_service_account.email
  container_spec_gcs_path = "${google_storage_bucket.staging_bucket.name}/${var.dataflow_job_file}"
}

output "staging_bucket_name" {
  value = google_storage_bucket.staging_bucket.name
}

output "dataflow_service_account_email" {
  value = google_service_account.dataflow_service_account.email
}

output "dataflow_job_id" {
  value = google_dataflow_flex_template_run.dataflow_job.id
}