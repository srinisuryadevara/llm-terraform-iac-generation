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
variable "staging_bucket_name" {}
variable "service_account_email" {}
variable "dataflow_job_name" {}
variable "dataflow_job_file" {}
variable "dataflow_job_args" {
  type = list(string)
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
  name     = var.staging_bucket_name
  location = var.region
  force_destroy = true
}

resource "google_service_account" "dataflow_service_account" {
  account_id   = "dataflow-service-account"
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
  launch_service           = "DATAFLOW"
  container_spec_gcs_path = "gs://${google_storage_bucket.staging_bucket.name}/${var.dataflow_job_file}"
  parameters = {
    "args" = join(" ", var.dataflow_job_args)
  }
  service_account_email = google_service_account.dataflow_service_account.email
}

output "staging_bucket_name" {
  value = google_storage_bucket.staging_bucket.name
}

output "dataflow_job_id" {
  value = google_dataflow_flex_template_run.dataflow_job.id
}

output "dataflow_job_status" {
  value = google_dataflow_flex_template_run.dataflow_job.status
}