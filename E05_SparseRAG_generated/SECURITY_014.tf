locals {
  project         = var.project
  location        = var.location
  bucket_name     = var.bucket_name
}

variable "project" {
  type        = string
  description = "The ID of the project"
}

variable "location" {
  type        = string
  description = "The location of the bucket"
}

variable "bucket_name" {
  type        = string
  description = "The name of the bucket"
}

variable "lifecycle_rule_age" {
  type        = number
  description = "The age of objects to delete"
}

provider "google" {
  project = local.project
  region  = local.location
}

resource "google_storage_bucket" "private_bucket" {
  name               = local.bucket_name
  location           = local.location
  bucket_policy_only = true
  uniform_bucket_level_access = true
}

resource "google_storage_bucket_iam_binding" "private_bucket" {
  bucket = google_storage_bucket.private_bucket.name
  role   = "roles/storage.objectViewer"
  members = [
    "serviceAccount:${google_service_account.private_bucket.email}",
  ]
}

resource "google_service_account" "private_bucket" {
  account_id   = "private-bucket-sa"
  display_name = "Private Bucket Service Account"
}

resource "google_storage_bucket_lifecycle_rule" "private_bucket" {
  bucket = google_storage_bucket.private_bucket.name
  rule {
    action {
      type = "Delete"
    }
    condition {
      age = var.lifecycle_rule_age
    }
  }
}