provider "google" {
  project = var.project_id
  region  = var.region
}

variable "project_id" {
  type        = string
  description = "The ID of the project"
}

variable "region" {
  type        = string
  description = "The region to deploy to"
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
  description = "The email of the service account"
}

resource "google_storage_bucket" "staging_bucket" {
  name                        = var.staging_bucket_name
  location                    = var.region
  force_destroy               = true
  uniform_bucket_level_access = true
  versioning {
    enabled = true
  }
  encryption {
    default_kms_key_name = google_kms_key.staging_bucket_key.id
  }
  labels = {
    environment = "production"
    project     = var.project_id
  }
}

resource "google_kms_key_ring" "staging_bucket_key_ring" {
  name     = "staging-bucket-key-ring"
  location = var.region
  project  = var.project_id
}

resource "google_kms_key" "staging_bucket_key" {
  name            = "staging-bucket-key"
  key_ring        = google_kms_key_ring.staging_bucket_key_ring.id
  rotation_period = "7776000s"
}

resource "google_service_account" "dataflow_service_account" {
  account_id = "dataflow-service-account"
  project    = var.project_id
}

resource "google_service_account_key" "dataflow_service_account_key" {
  service_account_id = google_service_account.dataflow_service_account.id
}

resource "google_iam_policy" "dataflow_service_account_policy" {
  name        = "dataflow-service-account-policy"
  project     = var.project_id
  description = "Policy for Dataflow service account"

  policy_data = jsonencode({
    "version" : "1",
    "bindings" : [
      {
        "role" : "roles/dataflow.worker",
        "members" : [
          "serviceAccount:${google_service_account.dataflow_service_account.email}",
        ]
      },
      {
        "role" : "roles/storage.objectCreator",
        "members" : [
          "serviceAccount:${google_service_account.dataflow_service_account.email}",
        ]
      },
    ]
  })
}

resource "google_iam_role" "dataflow_service_account_role" {
  name        = "dataflow-service-account-role"
  project     = var.project_id
  description = "Role for Dataflow service account"

  permissions = [
    "dataflow.jobs.create",
    "dataflow.jobs.get",
    "dataflow.jobs.update",
    "dataflow.jobs.delete",
    "storage.objects.create",
    "storage.objects.get",
    "storage.objects.update",
    "storage.objects.delete",
  ]
}

resource "google_dataflow_job" "example" {
  name                = var.dataflow_job_name
  template_gcs_path   = "gs://${google_storage_bucket.staging_bucket.name}/template"
  temp_gcs_location   = "gs://${google_storage_bucket.staging_bucket.name}/temp"
  service_account_email = google_service_account.dataflow_service_account.email
  labels = {
    environment = "production"
    project     = var.project_id
  }
}