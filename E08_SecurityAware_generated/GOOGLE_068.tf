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

variable "staging_bucket_name" {
  type        = string
  description = "The name of the staging bucket"
}

variable "service_account_email" {
  type        = string
  description = "The email of the service account"
}

resource "google_storage_bucket" "staging" {
  name                        = var.staging_bucket_name
  location                    = var.region
  force_destroy               = true
  uniform_bucket_level_access = true
  versioning {
    enabled = true
  }
  encryption {
    default_kms_key_name = google_kms_key.staging.self_link
  }
  labels = {
    environment = "production"
  }
}

resource "google_kms_key_ring" "staging" {
  name     = "staging-keyring"
  location = var.region
  labels = {
    environment = "production"
  }
}

resource "google_kms_key" "staging" {
  name            = "staging-key"
  key_ring        = google_kms_key_ring.staging.self_link
  rotation_period = "100000s"
  labels = {
    environment = "production"
  }
}

resource "google_service_account" "dataflow" {
  account_id = "dataflow-sa"
  description = "Service account for Dataflow job"
  labels = {
    environment = "production"
  }
}

resource "google_service_account_key" "dataflow" {
  service_account_id = google_service_account.dataflow.id
  public_key_type    = "TYPE_X509_PEM_FILE"
  labels = {
    environment = "production"
  }
}

resource "google_iam_role" "dataflow" {
  name        = "dataflow-role"
  description = "Role for Dataflow job"
  permissions = [
    "dataflow.jobs.create",
    "dataflow.jobs.update",
    "dataflow.jobs.get",
    "dataflow.jobs.list",
    "dataflow.jobs.delete",
    "storage.buckets.get",
    "storage.objects.get",
    "storage.objects.list",
    "storage.objects.create",
    "storage.objects.update",
    "storage.objects.delete",
  ]
  labels = {
    environment = "production"
  }
}

resource "google_iam_policy" "dataflow" {
  name        = "dataflow-policy"
  description = "Policy for Dataflow job"
  policy_type = "CUSTOM"
  bindings {
    role = google_iam_role.dataflow.id
    members = [
      "serviceAccount:${google_service_account.dataflow.email}",
    ]
  }
  labels = {
    environment = "production"
  }
}

resource "google_iam_binding" "dataflow" {
  role = google_iam_role.dataflow.name
  members = [
    "serviceAccount:${google_service_account.dataflow.email}",
  ]
}

resource "google_dataflow_flex_template" "example" {
  provider           = google
  project             = var.project_id
  region              = var.region
  template_gcp_path   = "gs://${google_storage_bucket.staging.name}/template"
  container_spec_gcp_path = "gs://${google_storage_bucket.staging.name}/container-spec"
  service_account_email = google_service_account.dataflow.email
  labels = {
    environment = "production"
  }
}

resource "google_compute_firewall" "ssh" {
  name    = "ssh-firewall"
  network = "default"
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  source_ranges = [var.ssh_cidr]
  target_tags = ["ssh"]
  labels = {
    environment = "production"
  }
}