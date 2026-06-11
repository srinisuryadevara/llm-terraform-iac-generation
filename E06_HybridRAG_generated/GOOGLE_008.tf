terraform {
  backend "gcs" {
    prefix  = "terraform/state"
    bucket  = var.bucket_name
  }
}

provider "google" {
  project     = var.project_id
  region      = var.region
}

variable "project_id" {
  type        = string
  description = "The ID of the project to create the bucket in"
}

variable "region" {
  type        = string
  description = "The region to create the bucket in"
  default     = "us-central1"
}

variable "bucket_name" {
  type        = string
  description = "The name of the bucket to create"
}

variable "location" {
  type        = string
  description = "The location of the bucket"
  default     = "US"
}

resource "google_storage_bucket" "uniform_bucket" {
  name               = var.bucket_name
  location           = var.location
  uniform_bucket_level_access = true
  force_destroy      = true
}

resource "google_storage_bucket_iam_binding" "private_binding" {
  bucket = google_storage_bucket.uniform_bucket.name
  role   = "roles/storage.objectViewer"
  members = [
    "projectEditor:${var.project_id}",
    "projectViewer:${var.project_id}",
  ]
}