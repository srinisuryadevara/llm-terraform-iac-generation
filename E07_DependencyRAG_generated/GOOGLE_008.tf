provider "google" {
  version = "~> 4.0"
  project = var.project_id
  region  = var.region
}

variable "project_id" {
  type        = string
  description = "The ID of the project to create the bucket in"
}

variable "region" {
  type        = string
  description = "The region to create the bucket in"
}

variable "bucket_name" {
  type        = string
  description = "The name of the bucket to create"
}

resource "google_storage_bucket" "uniform_bucket_access" {
  name     = var.bucket_name
  location = var.region
  uniform_bucket_level_access = true
  force_destroy = true
}

resource "google_storage_bucket_iam_policy" "private_policy" {
  bucket = google_storage_bucket.uniform_bucket_access.name
  policy_data = data.google_iam_policy.private_policy.policy_data
}

data "google_iam_policy" "private_policy" {
  binding {
    role = "roles/storage.objectViewer"
    members = [
      "serviceAccount:${google_service_account.storage_account.email}",
    ]
  }
}

resource "google_service_account" "storage_account" {
  account_id = "storage-account"
}

resource "google_storage_bucket_public_access_block" "block_public_access" {
  bucket                  = google_storage_bucket.uniform_bucket_access.name
  block_all               = true
}