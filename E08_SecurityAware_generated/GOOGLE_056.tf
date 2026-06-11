provider "google" {
  project = var.project_id
  region  = var.region
}

variable "project_id" {
  type        = string
  sensitive   = true
  description = "GCP Project ID"
}

variable "region" {
  type        = string
  description = "GCP Region"
}

variable "function_name" {
  type        = string
  description = "Cloud Function name"
}

variable "function_runtime" {
  type        = string
  description = "Cloud Function runtime"
}

variable "function_entry_point" {
  type        = string
  description = "Cloud Function entry point"
}

variable "function_source_archive_bucket" {
  type        = string
  description = "GCS bucket for Cloud Function source archive"
}

variable "function_source_archive_object" {
  type        = string
  description = "GCS object for Cloud Function source archive"
}

variable "service_account_email" {
  type        = string
  sensitive   = true
  description = "Service account email"
}

variable "vpc_network" {
  type        = string
  description = "VPC network for Cloud Function"
}

variable "vpc_subnetwork" {
  type        = string
  description = "VPC subnetwork for Cloud Function"
}

variable "tags" {
  type        = list(string)
  description = "Tags for Cloud Function"
}

resource "google_storage_bucket" "function_source_archive" {
  name                        = var.function_source_archive_bucket
  location                    = var.region
  force_destroy               = true
  uniform_bucket_level_access = true
  versioning {
    enabled = true
  }
  encryption {
    default_kms_key_name = google_kms_key.function_key.id
  }
  labels = var.tags
}

resource "google_kms_key_ring" "function_key_ring" {
  name     = "function-key-ring"
  location = var.region
  labels   = var.tags
}

resource "google_kms_key" "function_key" {
  name            = "function-key"
  key_ring        = google_kms_key_ring.function_key_ring.id
  rotation_period = "100000s"
  labels          = var.tags
}

resource "google_service_account" "function_service_account" {
  account_id = var.function_name
  description = "Service account for Cloud Function"
  depends_on  = [google_project_iam_binding.function_service_account_binding]
}

resource "google_project_iam_binding" "function_service_account_binding" {
  project = var.project_id
  role    = "roles/cloudfunctions.serviceAgent"
  members = [
    "serviceAccount:${google_service_account.function_service_account.email}",
  ]
}

resource "google_cloudfunctions_function" "function" {
  name        = var.function_name
  runtime     = var.function_runtime
  entry_point = var.function_entry_point
  source_archive_bucket = google_storage_bucket.function_source_archive.name
  source_archive_object = var.function_source_archive_object
  trigger_http {
    security_level = "SECURE_ALWAYS"
    url            = google_cloudfunctions_function.function.https_trigger_url
  }
  service_account_email = google_service_account.function_service_account.email
  vpc_connector         = google_vpc_access_connector.function_connector.id
  ingress_settings      = "ALLOW_ALL"
  labels               = var.tags
}

resource "google_vpc_access_connector" "function_connector" {
  name          = "function-connector"
  ip_cidr_range = "10.8.0.0/28"
  network       = var.vpc_network
  subnetwork    = var.vpc_subnetwork
  labels        = var.tags
}