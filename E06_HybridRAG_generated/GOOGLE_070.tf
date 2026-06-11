terraform {
  backend "gcs" {
    prefix  = "terraform/state"
    bucket  = var.bucket_name
  }
}

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
  default     = "us-central1"
  description = "The region of the bucket"
}

variable "bucket_name" {
  type        = string
  description = "The name of the bucket"
}

variable "location" {
  type        = string
  default     = "US"
  description = "The location of the bucket"
}

resource "google_storage_bucket" "uniform_bucket" {
  name               = var.bucket_name
  location           = var.location
  bucket_policy_only = true
  uniform_bucket_level_access = true
}

resource "google_storage_bucket_iam_binding" "private" {
  bucket = google_storage_bucket.uniform_bucket.name
  role   = "roles/storage.objectViewer"
  members = []
}