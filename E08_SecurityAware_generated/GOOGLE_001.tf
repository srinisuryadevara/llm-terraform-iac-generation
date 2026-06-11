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

variable "ssh_cidr" {
  type        = string
  description = "The CIDR to allow SSH from"
}

variable "dataflow_job_name" {
  type        = string
  description = "The name of the Dataflow job"
}

variable "dataflow_job_file" {
  type        = string
  description = "The file path of the Dataflow job"
}

variable "service_account_email" {
  type        = string
  description = "The email of the service account"
}

resource "google_storage_bucket" "staging_bucket" {
  name                        = "${var.project_id}-dataflow-staging-bucket"
  location                    = var.region
  force_destroy               = true
  uniform_bucket_level_access = true
  versioning {
    enabled = true
  }
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_key_name = google_kms_key.dataflow_key.id
      }
    }
  }
  labels = {
    environment = "dataflow"
  }
}

resource "google_kms_key_ring" "dataflow_key_ring" {
  name     = "dataflow-key-ring"
  location = var.region
  project  = var.project_id
}

resource "google_kms_key" "dataflow_key" {
  name            = "dataflow-key"
  key_ring        = google_kms_key_ring.dataflow_key_ring.id
  rotation_period = "100000s"
}

resource "google_service_account" "dataflow_service_account" {
  account_id = "dataflow-service-account"
  project    = var.project_id
}

resource "google_service_account_key" "dataflow_service_account_key" {
  service_account_id = google_service_account.dataflow_service_account.id
}

resource "google_iam_role" "dataflow_role" {
  name        = "dataflow-role"
  title       = "Dataflow Role"
  description = "A role for Dataflow"
  project     = var.project_id
  permissions = [
    "dataflow.jobs.create",
    "dataflow.jobs.update",
    "dataflow.jobs.get",
    "dataflow.jobs.list",
    "dataflow.jobs.delete",
    "storage.buckets.get",
    "storage.buckets.list",
    "storage.objects.create",
    "storage.objects.get",
    "storage.objects.list",
    "storage.objects.update",
    "storage.objects.delete",
  ]
}

resource "google_iam_binding" "dataflow_binding" {
  role    = google_iam_role.dataflow_role.id
  members = ["serviceAccount:${google_service_account.dataflow_service_account.email}"]
}

resource "google_dataflow_flex_template" "dataflow_job" {
  provider            = google
  project              = var.project_id
  region               = var.region
  template_gcs_path    = "gs://${google_storage_bucket.staging_bucket.name}/${var.dataflow_job_file}"
  service_account_email = google_service_account.dataflow_service_account.email
  parameters = {
    "input"  = "gs://${google_storage_bucket.staging_bucket.name}/input"
    "output" = "gs://${google_storage_bucket.staging_bucket.name}/output"
  }
  labels = {
    environment = "dataflow"
  }
}

resource "google_compute_firewall" "ssh_firewall" {
  name    = "ssh-firewall"
  network = "default"
  project = var.project_id
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  source_ranges = [var.ssh_cidr]
  target_tags   = ["dataflow"]
}