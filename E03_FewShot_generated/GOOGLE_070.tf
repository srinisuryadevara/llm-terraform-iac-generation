provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_storage_bucket" "uniform_bucket_access" {
  name                        = var.bucket_name
  location                    = var.region
  force_destroy               = true
  uniform_bucket_level_access = true
}

resource "google_storage_bucket_iam_policy" "uniform_bucket_access_policy" {
  bucket = google_storage_bucket.uniform_bucket_access.name
  policy_data = jsonencode({
    "version" : 1,
    "bindings" : [
      {
        "role" : "roles/storage.objectViewer",
        "members" : var.object_viewer_members
      },
      {
        "role" : "roles/storage.objectCreator",
        "members" : var.object_creator_members
      },
      {
        "role" : "roles/storage.objectAdmin",
        "members" : var.object_admin_members
      }
    ]
  })
}

resource "google_storage_bucket_public_access_prevention" "prevent_public_access" {
  bucket = google_storage_bucket.uniform_bucket_access.name
  prevention_type = "enforced"
}