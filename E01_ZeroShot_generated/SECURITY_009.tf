variable "project_id" {
  type = string
}

variable "bucket_name" {
  type = string
}

variable "location" {
  type = string
}

variable "storage_class" {
  type = string
}

variable "lifecycle_rule_age" {
  type = number
}

provider "google" {
  project = var.project_id
  region  = var.location
}

resource "google_storage_bucket" "bucket" {
  name                        = var.bucket_name
  location                    = var.location
  storage_class              = var.storage_class
  uniform_bucket_level_access = true
  force_destroy               = true

  lifecycle_rule {
    action {
      type = "Delete"
    }
    condition {
      age = var.lifecycle_rule_age
    }
  }
}

resource "google_storage_bucket_iam_policy" "bucket_policy" {
  bucket = google_storage_bucket.bucket.name
  policy = jsonencode({
    "version" = "2012-10-17"
    "statement" = [
      {
        "sid" = "DenyPublicAccess"
        "effect" = "Deny"
        "principal" = "*"
        "action" = [
          "s3:*",
        ]
        "resource" = [
          "arn:aws:s3:::${google_storage_bucket.bucket.name}",
          "arn:aws:s3:::${google_storage_bucket.bucket.name}/*",
        ]
        "condition" = {
          "stringlike" = {
            "aws:sourceip" = "*"
          }
        }
      },
    ]
  })
}