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

variable "ssh_source_cidr" {
  type        = string
  description = "The CIDR to allow SSH access from"
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
    default_kms_key_name = google_kms_key.dataflow_key.id
  }
  labels = {
    environment = "dataflow"
  }
}

resource "google_kms_key" "dataflow_key" {
  name            = "dataflow-key"
  location        = var.region
  key_ring        = google_kms_key_ring.dataflow_key_ring.id
  rotation_period = "100000s"
  labels = {
    environment = "dataflow"
  }
}

resource "google_kms_key_ring" "dataflow_key_ring" {
  name     = "dataflow-key-ring"
  location = var.region
  labels = {
    environment = "dataflow"
  }
}

resource "google_service_account" "dataflow_service_account" {
  account_id = "dataflow-service-account"
  description = "Service account for Dataflow job"
  labels = {
    environment = "dataflow"
  }
}

resource "google_service_account_key" "dataflow_service_account_key" {
  service_account_id = google_service_account.dataflow_service_account.id
}

resource "google_iam_role" "dataflow_role" {
  name        = "dataflow-role"
  description = "Role for Dataflow job"
  permissions = [
    "dataflow.jobs.create",
    "dataflow.jobs.get",
    "dataflow.jobs.update",
    "dataflow.jobs.delete",
    "storage.buckets.get",
    "storage.objects.get",
    "storage.objects.create",
    "storage.objects.delete",
  ]
  labels = {
    environment = "dataflow"
  }
}

resource "google_iam_policy" "dataflow_policy" {
  name        = "dataflow-policy"
  description = "Policy for Dataflow job"
  policy_data = data.google_iam_policy.dataflow_policy.data
  labels = {
    environment = "dataflow"
  }
}

data "google_iam_policy" "dataflow_policy" {
  binding {
    role = google_iam_role.dataflow_role.id
    members = [
      "serviceAccount:${google_service_account.dataflow_service_account.email}",
    ]
  }
}

resource "google_iam_role_assignment" "dataflow_role_assignment" {
  role       = google_iam_role.dataflow_role.id
  members    = ["serviceAccount:${google_service_account.dataflow_service_account.email}"]
  condition {
    title       = "dataflow-condition"
    description = "Condition for Dataflow job"
    expression  = "request.time < timestamp('2025-01-01T00:00:00.000Z')"
  }
  labels = {
    environment = "dataflow"
  }
}

resource "google_dataflow_flex_template_run" "dataflow_job" {
  provider           = google
  name               = var.dataflow_job_name
  template_gcs_path  = "gs://${google_storage_bucket.staging_bucket.name}/template"
  parameters         = {
    "input" = "gs://${google_storage_bucket.staging_bucket.name}/input"
    "output" = "gs://${google_storage_bucket.staging_bucket.name}/output"
  }
  service_account_email = google_service_account.dataflow_service_account.email
  labels = {
    environment = "dataflow"
  }
}

resource "google_compute_firewall" "ssh_firewall" {
  name    = "ssh-firewall"
  network = "default"
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  source_ranges = [var.ssh_source_cidr]
  target_tags   = ["dataflow"]
  labels = {
    environment = "dataflow"
  }
}