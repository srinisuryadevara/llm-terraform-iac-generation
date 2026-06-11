variable "project_id" {
  type        = string
  sensitive   = true
}

variable "bucket_name" {
  type        = string
}

variable "location" {
  type        = string
}

variable "storage_class" {
  type        = string
}

resource "google_storage_bucket" "example" {
  project                     = var.project_id
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

output "bucket_name" {
  value       = google_storage_bucket.example.name
  description = "The name of the bucket"
}

output "bucket_self_link" {
  value       = google_storage_bucket.example.self_link
  description = "The self link of the bucket"
}