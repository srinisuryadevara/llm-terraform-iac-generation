provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_storage_bucket" "cloud_functions_bucket" {
  name                        = "${var.project_id}-cloud-functions-bucket"
  location                    = var.region
  force_destroy               = true
  uniform_bucket_level_access = true
  versioning {
    enabled = true
  }
  encryption {
    default_kms_key_name = google_kms_key.cloud_functions_key.id
  }
  labels = {
    environment = var.environment
  }
}

resource "google_kms_key_ring" "cloud_functions_key_ring" {
  name     = "${var.project_id}-cloud-functions-key-ring"
  location = var.region
  labels = {
    environment = var.environment
  }
}

resource "google_kms_key" "cloud_functions_key" {
  name            = "${var.project_id}-cloud-functions-key"
  key_ring        = google_kms_key_ring.cloud_functions_key_ring.id
  rotation_period = "7776000s"
  labels = {
    environment = var.environment
  }
}

resource "google_service_account" "cloud_functions_service_account" {
  account_id = "${var.project_id}-cloud-functions-sa"
  description = "Service account for Cloud Functions"
  labels = {
    environment = var.environment
  }
}

resource "google_service_account_key" "cloud_functions_service_account_key" {
  service_account_id = google_service_account.cloud_functions_service_account.id
  public_key_type    = "TYPE_X509_PEM_FILE"
  key_algorithm      = "KEY_ALG_RSA_2048"
  labels = {
    environment = var.environment
  }
}

resource "google_cloudfunctions_function" "example" {
  name        = "${var.project_id}-cloud-functions-example"
  runtime     = "nodejs14"
  region      = var.region
  entry_point = "helloWorld"
  available_memory_mb   = 128
  source_archive_bucket = google_storage_bucket.cloud_functions_bucket.name
  source_archive_object = "cloud-functions-source.zip"
  trigger_http {
    security_level = "SECURE_ALWAYS"
    url            = google_cloudfunctions_function.example.https_trigger_url
    ingress_settings = "ALLOW_ALL"
  }
  service_account_email = google_service_account.cloud_functions_service_account.email
  labels = {
    environment = var.environment
  }
}

resource "google_cloudfunctions_function_iam_member" "invoker" {
  cloud_function = google_cloudfunctions_function.example.name
  role          = "roles/cloudfunctions.invoker"
  member        = "serviceAccount:${google_service_account.cloud_functions_service_account.email}"
}

variable "project_id" {
  type = string
}

variable "region" {
  type = string
}

variable "environment" {
  type = string
}