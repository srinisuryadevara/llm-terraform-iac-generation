terraform {
  backend "gcs" {
    prefix  = "terraform/state"
    bucket  = var.bucket_name
  }
}

variable "project" {
  type        = string
  description = "GCP Project ID"
}

variable "region" {
  type        = string
  default     = "us-central1"
  description = "GCP Region"
}

variable "bucket_name" {
  type        = string
  description = "GCS Bucket Name"
}

variable "service_account_email" {
  type        = string
  description = "Service Account Email"
}

variable "dataflow_job_name" {
  type        = string
  description = "Dataflow Job Name"
}

provider "google" {
  project = var.project
  region  = var.region
}

provider "google-beta" {
  project = var.project
  region  = var.region
}

resource "google_storage_bucket" "staging_bucket" {
  name     = "${var.project}-dataflow-staging-bucket"
  location = var.region
}

resource "google_service_account" "dataflow_service_account" {
  account_id = "dataflow-service-account"
}

resource "google_service_account_key" "dataflow_service_account_key" {
  service_account_id = google_service_account.dataflow_service_account.id
}

resource "google_iam_role" "dataflow_worker" {
  name        = "dataflow-worker"
  description = "Dataflow Worker Role"
}

resource "google_iam_role" "dataflow_runner" {
  name        = "dataflow-runner"
  description = "Dataflow Runner Role"
}

resource "google_iam_binding" "dataflow_worker_binding" {
  role = google_iam_role.dataflow_worker.id
  members = [
    "serviceAccount:${google_service_account.dataflow_service_account.email}",
  ]
}

resource "google_iam_binding" "dataflow_runner_binding" {
  role = google_iam_role.dataflow_runner.id
  members = [
    "serviceAccount:${google_service_account.dataflow_service_account.email}",
  ]
}

resource "google_dataflow_job" "example_job" {
  name                = var.dataflow_job_name
  temp_gcs_location   = "${google_storage_bucket.staging_bucket.name}/temp"
  max_workers         = 10
  service_account_email = google_service_account.dataflow_service_account.email
  machine_type        = "n1-standard-1"
  network             = "default"
  subnetwork          = "default"
  ip_configuration    = "WORKER_IP_PUBLIC"
  on_delete           = "CANCEL"
}

output "staging_bucket_name" {
  value = google_storage_bucket.staging_bucket.name
}

output "dataflow_job_name" {
  value = google_dataflow_job.example_job.name
}

output "service_account_email" {
  value = google_service_account.dataflow_service_account.email
}