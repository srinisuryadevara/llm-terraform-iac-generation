variable "project_id" {
  type        = string
  description = "The ID of the project to create the bucket in"
}

variable "bucket_name" {
  type        = string
  description = "The name of the bucket to create"
}

variable "location" {
  type        = string
  description = "The location of the bucket to create"
}

variable "storage_class" {
  type        = string
  description = "The storage class of the bucket to create"
}

provider "google" {
  project = var.project_id
  region  = var.location
}

resource "google_storage_bucket" "example" {
  name                        = var.bucket_name
  location                    = var.location
  storage_class               = var.storage_class
  uniform_bucket_level_access = true
  force_destroy               = true

  lifecycle_rule {
    condition {
      age = 30
    }
    action {
      type = "Delete"
    }
  }
}

resource "google_storage_bucket_iam_policy" "example" {
  bucket = google_storage_bucket.example.name
  policy = jsonencode({
    "bindings" : [
      {
        "role" : "roles/storage.objectViewer",
        "members" : [
          "serviceAccount:${var.project_id}@gs-project-accounts.iam.gserviceaccount.com"
        ]
      }
    ]
  })
}