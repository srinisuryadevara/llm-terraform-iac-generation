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

resource "google_storage_bucket" "uniform_bucket" {
  name     = var.bucket_name
  location = var.region
  uniform_bucket_level_access = true
  force_destroy = true
}

resource "google_storage_bucket_iam_policy" "private_policy" {
  bucket = google_storage_bucket.uniform_bucket.name
  policy_data = jsonencode({
    "version" = "1"
    "bindings" = [
      {
        "role" = "roles/storage.objectViewer"
        "members" = [
          "projectEditor:$(google_storage_bucket.uniform_bucket.project)",
          "projectViewer:$(google_storage_bucket.uniform_bucket.project)",
        ]
      },
    ]
  })
}

resource "google_storage_bucket_iam_binding" "binding" {
  bucket = google_storage_bucket.uniform_bucket.name
  role   = "roles/storage.objectViewer"
  members = [
    "projectEditor:$(google_storage_bucket.uniform_bucket.project)",
    "projectViewer:$(google_storage_bucket.uniform_bucket.project)",
  ]
}