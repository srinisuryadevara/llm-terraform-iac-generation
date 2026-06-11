provider "google" {
  version = "~> 2.0"
  region      = var.region
}

variable "region" {
  default = "us-central1"
}

variable "project" {
  default = "my-project"
}

variable "function_name" {
  default = "my-function"
}

variable "runtime" {
  default = "nodejs14"
}

variable "service_account_email" {
  default = "my-service-account@my-project.iam.gserviceaccount.com"
}

resource "google_service_account" "service_account" {
  account_id = "my-service-account"
  project    = var.project
}

resource "google_service_account_key" "service_account_key" {
  service_account_id = google_service_account.service_account.id
}

resource "google_cloudfunctions_function" "function" {
  name        = var.function_name
  runtime     = var.runtime
  service_account_email = google_service_account.service_account.email
  available_memory_mb   = 128
  trigger {
    http_method = "GET"
    url_path    = "/my-path"
  }
  source_archive_bucket = google_storage_bucket.source_archive_bucket.name
  source_archive_object = google_storage_bucket_object.source_archive_object.name
}

resource "google_storage_bucket" "source_archive_bucket" {
  name     = "${var.project}-source-archive-bucket"
  location = var.region
}

resource "google_storage_bucket_object" "source_archive_object" {
  name   = "source-archive-object.zip"
  bucket = google_storage_bucket.source_archive_bucket.name
  source = file("./path/to/source/archive/object.zip")
}

resource "google_cloudfunctions_function_iam_member" "invoker" {
  project        = var.project
  region         = var.region
  cloud_function = google_cloudfunctions_function.function.name
  role           = "roles/cloudfunctions.invoker"
  member         = "allUsers"
}